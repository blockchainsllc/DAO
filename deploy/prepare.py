#!/usr/bin/python2

import json
import subprocess
import argparse
import os
import inspect

contracts_dir = "../"
currentdir = os.path.dirname(
    os.path.abspath(inspect.getfile(inspect.currentframe()))
)
os.sys.path.insert(0, os.path.dirname(currentdir))
from tests.utils import determine_binary, edit_dao_source, rm_file


class TestDeployContext():
    def __init__(self, args):
        self.args = args
        self.args.solc = determine_binary(args.solc, 'solc')

    def compile_contract(self, contract_name):
        if self.args.no_limits:
            contract_path = edit_dao_source(
                self.args.contracts_dir,
                False,
                True,
                self.args.split_execution_period,
                False
            )
        else:
            contract_path = os.path.join(
                self.args.contracts_dir,
                contract_name
            )
        print("    Compiling {}...".format(contract_path))
        data = subprocess.check_output([
          self.args.solc,
          contract_path,
          "--optimize",
          "--combined-json",
          "abi,bin"
        ])
        return json.loads(data)

    def cleanup(self):
        if self.args.no_limits:
            rm_file(os.path.join(self.args.contracts_dir, "DAOcopy.sol"))
            rm_file(
                os.path.join(self.args.contracts_dir, "TokenCreationCopy.sol")
            )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description='DAO deployment script')
    p.add_argument(
        '--solc',
        help='Full path to the solc binary to use'
    )
    p.add_argument(
        '--creation-duration-mins',
        type=int,
        default=60,
        help='Deployed DAO creation duration in minutes'
    )
    p.add_argument(
        '--contracts-dir',
        default="..",
        help='The directory where the contracts are located'
    )
    p.add_argument(
        '--no-limits',
        action='store_true',
        help='If given then a version of DAO.sol without limits is compiled'
    )
    p.add_argument(
        '--curator',
        default="0x0f9B5B4646215E05fBedBdBB0244e198249Da962",  # Bill testnet etherbase
        help='Account to set as the curator'
    )
    p.add_argument(
        '--default-proposal-deposit',
        type=int,
        default=10,
        help='The proposal deposit (in ether) for every proposal of the DAO'
    )
    p.add_argument(
        '--split-execution-period',
        type=int,
        default=20,
        help=(
            'Number of seconds after the voting deadline for which a split '
            'proposal is executable'
        )
    )
    args = p.parse_args()
    ctx = TestDeployContext(args)
    comp = ctx.compile_contract("DAO.sol")

    with open("prepare.js", "w") as f:
        f.write("dao_abi = {};\n".format(comp['contracts']['DAO']['abi']))
        f.write("dao_bin = '{}';\n".format(comp['contracts']['DAO']['bin']))
        f.write("creator_abi = {};\n".format(
          comp['contracts']['DAO_Creator']['abi'])
        )
        f.write("creator_bin = '{}';\n".format(
          comp['contracts']['DAO_Creator']['bin'])
        )
        f.write("seconds_from_now = {};\n".format(
          args.creation_duration_mins * 60)
        )
        f.write("curator = \"{}\";\n".format(args.curator))
        f.write("default_proposal_deposit = {};\n".format(
            args.default_proposal_deposit)
        )

    ctx.cleanup()
