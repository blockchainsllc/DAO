#!/usr/bin/python2

# Use test.py with any valid combination of arguments in order to run
# DAO test scenarios

import os
import json
import subprocess
import shutil
import sys
import textwrap
import importlib
import inspect
from string import Template
from utils import (
    rm_file, determine_binary, ts_now, write_js, available_scenarios,
    create_genesis, edit_dao_source, eval_test,
)
from args import test_args


class TestContext():
    def __init__(self, args):
        self.running_scenarios = []
        self.ran_scenarios = []
        self.args = args
        self.tests_ok = True
        self.dao_addr = None
        self.offer_addr = None
        self.token_amounts = None
        self.tests_dir = os.path.dirname(os.path.realpath(__file__))
        datadir = os.path.join(self.tests_dir, "data")
        self.save_file = os.path.join(datadir, "saved")
        self.templates_dir = os.path.join(self.tests_dir, 'templates')
        self.contracts_dir = os.path.dirname(self.tests_dir)
        self.solc = determine_binary(args.solc, 'solc')
        self.geth = determine_binary(args.geth, 'geth')

        if args.describe_scenarios:
            self.describe_scenarios()
            sys.exit(0)

        # keep this at end since any data loaded should override constructor
        if not os.path.isdir(datadir) or args.clean_chain:
            self.clean_blockchain()
            self.init_data(args.users_num)
        else:
            self.attemptLoad()

    def init_data(self, accounts_num):
        print("Creating accounts and genesis block ...")
        with open(
                os.path.join(self.templates_dir, 'accounts.template.js'),
                'r'
        ) as f:
            data = f.read()
        tmpl = Template(data)
        s = tmpl.substitute(accounts_number=accounts_num)
        with open('accounts.js', "w") as f:
            f.write(s)
        output = self.run_script('accounts.js')
        self.accounts = json.loads(output)
        # creating genesis block with a generous allocation for all accounts
        create_genesis(self.accounts)
        # now initialize geth with the new blockchain
        subprocess.check_output([
            self.geth, "--datadir", "./data", "init", "./genesis_block.json"
        ])
        print("Done!")

    def remaining_time(self):
        return self.closing_time - ts_now()

    def attemptLoad(self):
        """
        If there is a saved file, then attempt to load DAO data from there
        """
        if os.path.isfile(self.save_file):
            print("Loading DAO from a saved file...")
            with open(self.save_file, 'r') as f:
                data = json.loads(f.read())
            self.dao_addr = data['dao_addr']
            self.dao_creator_addr = data['dao_creator_addr']
            self.offer_addr = data['offer_addr']
            self.closing_time = data['closing_time']
            print("Loaded dao_addr: {}".format(self.dao_addr))
            print("Loaded dao_creator_addr: {}".format(self.dao_creator_addr))

    def clean_blockchain(self):
        """Clean all blockchain data directories apart from the keystore"""
        print("Cleaning blockchain data directory ...")
        data_dir = os.path.join(self.tests_dir, "data")
        shutil.rmtree(os.path.join(data_dir, "chaindata"), ignore_errors=True)
        shutil.rmtree(os.path.join(data_dir, "dapp"), ignore_errors=True)
        shutil.rmtree(os.path.join(data_dir, "keystore"), ignore_errors=True)
        rm_file(os.path.join(data_dir, "nodekey"))
        rm_file(os.path.join(data_dir, "saved"))

    def run_script(self, script):
        if script == 'accounts.js':
            return subprocess.check_output([
                self.geth,
                "--networkid",
                "123",
                "--nodiscover",
                "--maxpeers",
                "0",
                "--datadir",
                "./data",
                "--verbosity",
                "0",
                "js",
                script
            ])
        else:
            print("Running '{}' script".format(script))
            return subprocess.check_output([
                self.geth,
                "--networkid",
                "123",
                "--nodiscover",
                "--maxpeers",
                "0",
                "--datadir",
                "./data",
                "--verbosity",
                "0",
                "js",
                script
            ])

    def compile_contract(self, contract_path):
        print("    Compiling {}...".format(contract_path))
        data = subprocess.check_output([
            self.solc,
            contract_path,
            "--optimize",
            "--combined-json",
            "abi,bin"
        ])
        return json.loads(data)

    def compile_contracts(self, keep_limits):
        if not self.solc:
            print("Error: No valid solc compiler provided")
            sys.exit(1)
        print("Compiling the DAO contracts...")

        dao_contract = os.path.join(self.contracts_dir, "DAO.sol")
        if not os.path.isfile(dao_contract):
            print("DAO contract not found at {}".format(dao_contract))
            sys.exit(1)
        dao_contract = edit_dao_source(
            self.contracts_dir,
            keep_limits,
            1,  # min_proposal_debate
            1,  # min_proposal_split
            self.args.proposal_halveminquorum,
            self.args.split_execution_period,
            self.scenario_uses_extrabalance(),
            self.args.scenario == "fuel_fail_extrabalance",
            self.args.deploy_offer_payment_period
        )
        usn = os.path.join(self.contracts_dir, "USNRewardPayOutCopy.sol")
        res = self.compile_contract(usn)
        contract = res["contracts"]["DAO"]
        DAOCreator = res["contracts"]["DAO_Creator"]
        self.creator_abi = DAOCreator["abi"]
        self.creator_bin = DAOCreator["bin"]
        self.dao_abi = contract["abi"]
        self.dao_bin = contract["bin"]
        self.offer_abi = res["contracts"]["SampleOffer"]["abi"]
        self.offer_bin = res["contracts"]["SampleOffer"]["bin"]
        self.usn_abi = res["contracts"]["USNRewardPayOut"]["abi"]
        self.usn_bin = res["contracts"]["USNRewardPayOut"]["bin"]

        # also delete the temporary created files
        rm_file(os.path.join(self.contracts_dir, "DAOcopy.sol"))
        rm_file(os.path.join(self.contracts_dir, "TokenCreationCopy.sol"))
        rm_file(os.path.join(self.contracts_dir, "SampleOfferCopy.sol"))
        rm_file(os.path.join(self.contracts_dir, "SampleOfferWithoutRewardCopy.sol"))
        rm_file(os.path.join(self.contracts_dir, "USNRewardPayOutCopy.sol"))

    def create_js_file(self, substitutions, cb_before_creation=None):
        """
        Creates a js file from a template

        Parameters
        ----------
        name : string
        The name of the javascript file without the '.js' extension

        substitutions : dict
        A dict of the substitutions to make in the template
        file in order to produce the final js

        cb_before_creation : function
        (Optional) A callback function to be called right before substitution.
        It should accept the following arguments:
        (test_framework_object, name_of_js_file, substitutions_dict)
        and it returns the edited substitutions map
        """
        name = self.running_scenario()
        print("Creating {}.js".format(name))
        scenario_dir = os.path.join(self.tests_dir, "scenarios", name)
        with open(
                os.path.join(scenario_dir, 'template.js'),
                'r'
        ) as f:
            data = f.read()
        tmpl = Template(data)
        if cb_before_creation:
            substitutions = cb_before_creation(self, name, substitutions)
        s = tmpl.substitute(substitutions)
        write_js("{}.js".format(name), s, len(self.accounts))

    def execute(self, expected):
        output = self.run_script('{}.js'.format(self.running_scenario()))
        return eval_test(self.running_scenario(), output, expected)

    def scenario_uses_extrabalance(self):
        """
        Check if the target scenario requires late sale, in order to
        populate the extraBalance account
        """
        return ctx.args.scenario in [
            "extrabalance",
            "stealextrabalance",
            "fuel_fail_extrabalance"
        ]

    def running_scenario(self):
        """Get the currently running scenario name"""
        return self.running_scenarios[-1]

    def describe_scenarios(self):
        """Get all scenario descriptions and print them in the screen"""
        print("Available scenarios for DAO testing.")
        for name in available_scenarios():
            scenario = importlib.import_module(
                "scenarios.{}.run".format(name)
            )
            print("== {} ==\n{}.\n".format(
                name,
                textwrap.fill(scenario.scenario_description)
            ))

    def assert_scenario_ran(self, name):
        if name not in self.ran_scenarios:
            self.run_scenario(name)
            return False
        return True

    def run_scenario(self, name):
        if name == 'None':
            print("Asked to run no scenario. Quitting ...")
            return
        self.running_scenarios.append(name)
        scenario = importlib.import_module("scenarios.{}.run".format(name))
        scenario.run(self)
        self.running_scenarios.pop()
        self.ran_scenarios.append(name)

    def run_test(self, args):
        if not self.geth:
            print("Error: No valid geth binary provided/found")
            sys.exit(1)
        # All scenarios would need to have the contracts compiled
        self.compile_contracts(args.keep_limits)
        self.run_scenario(self.args.scenario)

if __name__ == "__main__":
    currentdir = os.path.dirname(
        os.path.abspath(inspect.getfile(inspect.currentframe()))
    )
    os.sys.path.insert(0, currentdir)
    args = test_args()
    ctx = TestContext(args)
    ctx.run_test(args)
