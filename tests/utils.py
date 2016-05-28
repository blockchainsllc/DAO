#!/usr/bin/python2
import calendar
import random
import os
import json
import sys
import re
from sha3 import sha3_256 as sha3
from datetime import datetime
from jsutils import js_common_intro


def constrained_sum_sample_pos(n, total):
    """Return a randomly chosen list of n positive integers summing to total.
    Each such list is equally likely to occur."""

    dividers = sorted(random.sample(xrange(1, total), n - 1))
    return [a - b for a, b in zip(dividers + [total], [0] + dividers)]


def is_exe(fpath):
    return os.path.isfile(fpath) and os.access(fpath, os.X_OK)


def rm_file(f):
    try:
        os.remove(f)
    except OSError:
        pass


def which(program):
    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None


def determine_binary(given_binary, name):
    """
    Determines if a path to a binary is correct and if not tries to
    get a generic one by looking at the system PATH
    """
    if given_binary:
        if is_exe(given_binary):
            return given_binary
    else:
        # try to find binary in the PATH
        return which(name)
    return None


def ts_now():
    """ Return a unix timestamp representing the time in UTC right now"""
    return calendar.timegm(datetime.utcnow().utctimetuple())


def seconds_in_future(secs):
    return ts_now() + secs


def create_votes_array(amounts, approve, reverse):
    """
    Create an array of votes out of the tokens holders to either pass or
    reject a proposal.
        Parameters
        ----------
        amounts : list
        The list of tokens each token holder has

        approve : bool
        True if we want to pass and false if we want to vote against
        the proposal

        reverse : bool
        True if we need to iterate the list in reverse to give chance for
        True votes to the last accounts

        Returns
        ----------
        The array of votes required
    """
    votes = []
    total = sum(amounts)
    amounts_for_traversal = list(reversed(amounts)) if reverse else amounts
    percentage = 0.0

    if not approve:
        for val in amounts_for_traversal:
            ratio = val/float(total)
            if (percentage + ratio < 0.5):
                votes.append(True)
                percentage += ratio
            else:
                votes.append(False)
    else:
        for val in amounts_for_traversal:
            ratio = val/float(total)
            if percentage <= 0.5:
                votes.append(True)
                percentage += ratio
            else:
                votes.append(False)

    return list(reversed(votes)) if reverse else votes


def create_votes_array_for_quorum(amounts, targetQuorum, approve):
    """
    Create an array of votes for a proposal that will reach a targetQuorum
        Parameters
        ----------
        amounts : list
        The list of tokens each token holder has

        targetQuorum : float
        A target quorum represented by a float ranging from 0.0 to 1.0. It
        represents percentage of the quorum we want to achieve

        approve : bool
        True if we want to pass and false if we want to vote against
        the proposal

        Returns
        ----------
        The array of votes required
    """
    votes = []
    total = sum(amounts)
    percentage = 0.0

    for val in amounts:
        ratio = val/float(total)
        if (percentage + ratio < targetQuorum):
            votes.append(approve)
            percentage += ratio
        else:
            break
    if not votes or percentage > targetQuorum:
        print("ERROR: Could not satisfy the target quorum of '{}' with the "
              "currrent way the token holders bought tokens. Please rerun the "
              "test in order to get a different set of token holders")
        sys.exit(1)
    return votes


def arr_str(arr):
    """
    Create a string representation of an array, ready to be imported to js.
        Parameters
        ----------
        arr : list
        The list from which to create the array string. Can be an array of
        ints, strings or booleans

        Returns
        ----------
        A string representation of the array ready to be imported in a js
        template
    """
    if type(arr) is not list or arr == []:
        print("ERROR: 'arr_str()' expects a non-empty list")
        sys.exit(1)
    has_strings = isinstance(arr[0], basestring)
    return "[ {} ]".format(
        ', '.join(['"{}"'.format(
            str(x).lower()
        ) if has_strings else str(x).lower() for x in arr])
    )


def extract_test_dict(name, output):
    split = output.split('Test Results: ', 1)
    if len(split) != 2:
        print("ERROR: Could not parse '{}' output properly.\n"
              "Output was:\n{}".format(
                  name, output
              ))
        sys.exit(1)
    try:
        result = json.loads(split[1])
    except:
        print("ERROR: Could not parse '{}' output properly.\n"
              "Output was:\n{}".format(
                  name, output
              ))
        sys.exit(1)
    return result


def is_int(v):
    return isinstance(v, (int, long))


def cmp_floats(a, b):
    return abs(a - b) <= 0.01


def cmp_string_to_int(string, num):
    try:
        return int(string) == num
    except:
        return cmp_floats(float(string), float(num))


def compare_values(got, expect):
    if isinstance(got, float) ^ isinstance(expect, float):
        if is_int(got) or is_int(expect):
            return abs(expect - got) % 1 <= 0.01
        else:
            print("ERROR: float comparison failure")
            return False
    if isinstance(got, float):
        return cmp_floats(got, expect)
    elif isinstance(got, basestring) and is_int(expect):
        return cmp_string_to_int(got, expect)
    elif isinstance(expect, basestring) and is_int(got):
        return cmp_string_to_int(expect, got)
    elif isinstance(expect, basestring) and isinstance(got, float):
        return cmp_floats(float(expect), got)
    else:
        return got == expect


def eval_test(name, output, expected_dict):
    """
    Evaluate output of a scenario and compare with expected results
        Parameters
        ----------
        name : string
        The name of the scenario to evaluate

        output : string
        The output of the script that was executed, from which we will
        extract the results

        expected_dict : dict
        A dictionary containing all the expected output from the test

        Returns
        ----------
        results : dict
        The dictionary that resulted from the parsing of the test output
    """
    tests_fail = False
    results = extract_test_dict(name, output)

    for k, v in expected_dict.iteritems():
        if k not in results:
            tests_fail = True
            print("ERROR: Did not find '{}' in the test results".format(k))
            continue
        if not compare_values(results[k], v):
            tests_fail = True
            print("ERROR: Expected {} for '{}' but got {}".format(
                v, k, results[k]
            ))

    if not tests_fail:
        print("Tests for scenario '{}' PASSED!".format(name))
    else:
        print("Tests for scenario '{}' FAILED! Script output was:\n{}".format(
            name, output)
        )
        sys.exit(1)
    return results


def write_js(name, contents, accounts_num):
    """Write a javascript file from a template, prepending common intro"""
    with open(name, "w") as f:
            f.write("{}\n{}".format(js_common_intro(accounts_num), contents))


def create_genesis(accounts):
    """Create a genesis block with ether allocation for the given accounts"""
    genesis = {}
    config = {}
    config["homesteadBlock"] = 0
    genesis["config"] = config
    genesis["nonce"] = "0xdeadbeefdeadbeef"
    genesis["timestamp"] = "0x0"
    # Start after homesteam
    genesis["parentHash"] = (
        "0x0000000000000000000000000000000000000000000000000000000000000000"
    )
    genesis["extraData"] = "0x0"
    genesis["gasLimit"] = "0x47e7c4"
    genesis["difficulty"] = (
        "0x0000000000000000000000000000000000000000000000000000000000000001"
    )
    genesis["mixhash"] = (
        "0x0000000000000000000000000000000000000000000000000000000000000000"
    )
    alloc = {}
    for acc in accounts:
        alloc[acc] = {"balance": "133700000000000000000000000000000000"}
    genesis["alloc"] = alloc
    with open('genesis_block.json', "w") as f:
        f.write(json.dumps(genesis))


def count_token_votes(amounts, votes):
    """Returns how many tokens votes yay and how many voted nay"""
    yay = 0
    nay = 0
    for idx, amount in enumerate(amounts):
        if votes[idx]:
            yay += amount
        else:
            nay += amount
    return yay, nay


def str_replace_or_die(string, old, new):
    if old not in string:
        print(
            "ERROR: Could not find '{}' during DAO's source "
            "code editing for the tests.".format(old)
        )
        sys.exit(1)
    return string.replace(old, new)


def re_replace_or_die(string, varname, value):
    old_string = string
    new_string = re.sub(
        r"(uint constant *{} *=).*;".format(varname),
        r"\1 {};".format(value),
        string
    )
    if old_string == new_string:
        print(
            "ERROR: Could not match RE for '{}' during DAO's source "
            "code editing for the tests.".format(varname)
        )
        sys.exit(1)
    return new_string


def edit_dao_source(
        contracts_dir,
        keep_limits,
        min_proposal_debate,
        min_split_debate,
        halve_minquorum,
        split_exec_period,
        normal_pricing,
        extra_balance_refund,
        offer_payment_period):
    with open(os.path.join(contracts_dir, 'DAO.sol'), 'r') as f:
        contents = f.read()

    # remove all limits that would make testing impossible
    contents = re_replace_or_die(
        contents,
        "minProposalDebatePeriod",
        str(min_proposal_debate)
    )
    contents = re_replace_or_die(
        contents,
        "minSplitDebatePeriod",
        "1"
    )
    contents = re_replace_or_die(
        contents,
        "splitExecutionPeriod",
        str(split_exec_period)
    )

    if not extra_balance_refund:
        contents = re_replace_or_die(contents, "creationGracePeriod", "1")

    if halve_minquorum:  # if we are testing halve_minquorum remove year limit
        contents = re_replace_or_die(contents, "quorumHalvingPeriod", "1")

    # add test query functions
    contents = str_replace_or_die(
        contents,
        "contract DAO is DAOInterface, Token, TokenCreation {",
        """contract DAO is DAOInterface, Token, TokenCreation {

        function splitProposalBalance(uint pid, uint sid) constant returns (uint _balance) {
            Proposal p = proposals[pid];
            if (!p.newCurator) throw;
            SplitData s = p.splitData[sid];
            return s.splitBalance;
        }

        function splitProposalSupply(uint pid, uint sid) constant returns (uint _supply) {
            Proposal p = proposals[pid];
            if (!p.newCurator) throw;
            SplitData s = p.splitData[sid];
            return s.totalSupply;
        }

        function splitProposalrewardToken(uint pid, uint sid) constant returns (uint _rewardToken) {
            Proposal p = proposals[pid];
            if (!p.newCurator) throw;
            SplitData s = p.splitData[sid];
            return s.rewardToken;
        }

        function splitProposalNewAddress(uint pid, uint sid) constant returns (address _DAO) {
            Proposal p = proposals[pid];
            if (!p.newCurator) throw;
            SplitData s = p.splitData[sid];
            return address(s.newDAO);
        }

        function extMinQuorum(uint _val) constant returns (uint _minQuorum) {
            return minQuorum(_val);
        }
"""
    )
    contents = str_replace_or_die(
        contents,
        'import "./TokenCreation.sol";',
        'import "./TokenCreationCopy.sol";'
    )

    new_path = os.path.join(contracts_dir, "DAOcopy.sol")
    with open(new_path, "w") as f:
        f.write(contents)

    # edit TokenCreation source
    with open(os.path.join(contracts_dir, 'TokenCreation.sol'), 'r') as f:
        contents = f.read()

    if (not keep_limits) and (not normal_pricing):
        contents = str_replace_or_die(
            contents, 'closingTime - 2 weeks > now', 'true'
        )
    with open(os.path.join(contracts_dir, 'TokenCreationCopy.sol'), "w") as f:
        f.write(contents)

    # edit SampleOfferWithoutRewards.sol
    with open(os.path.join(contracts_dir, 'SampleOfferWithoutReward.sol'), 'r') as f:
        contents = f.read()

    contents = str_replace_or_die(
        contents,
        'import "./DAO.sol";',
        'import "./DAOcopy.sol";'
    )
    contents = str_replace_or_die(contents, '(1 days)', str(offer_payment_period))
    with open(os.path.join(contracts_dir, 'SampleOfferWithoutRewardCopy.sol'), "w") as f:
        f.write(contents)

    # edit SampleOffer.sol
    with open(os.path.join(contracts_dir, 'SampleOffer.sol'), 'r') as f:
        contents = f.read()

    contents = str_replace_or_die(
        contents,
        'import "./SampleOfferWithoutReward.sol";',
        'import "./SampleOfferWithoutRewardCopy.sol";'
    )
    with open(os.path.join(contracts_dir, 'SampleOfferCopy.sol'), "w") as f:
        f.write(contents)

    # edit USNRewardPayOut.sol
    with open(os.path.join(contracts_dir, 'USNRewardPayOut.sol'), 'r') as f:
        contents = f.read()

    contents = str_replace_or_die(
        contents,
        'import "./SampleOffer.sol";',
        'import "./SampleOfferCopy.sol";'
    )
    with open(os.path.join(contracts_dir, 'USNRewardPayOutCopy.sol'), "w") as f:
        f.write(contents)

    return new_path


def argtype_is_int(t):
    return t in ["uint256", "uint128"]


def calculate_bytecode(function_name, *args):
    """
    Create the bytecode for calling function with `function_name` and the
    given arguments as defined here:
    https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI#examples

        Parameters
        ----------
        function_hash : string
        The first 4 bytes of the hash of the function signature.

        args : list
        A list of arguments to encode. Each argument consists of a tuple of
        the argument type and its value.

        Returns
        ----------
        results : string
        The encoded ABI for the function call with the given arguments
    """

    # form the function's hash
    types = []
    for arg in args:
        types.append(arg[0])
    function_hash = "0x" + sha3("{}({})".format(
        function_name,
        ','.join(types)
    )).hexdigest()[:8]

    bytecode = function_hash
    for arg in args:
        arg_type = arg[0]
        arg_val = arg[1]
        if arg_type == "bool" or argtype_is_int(arg_type):
            if arg_type == "bool":
                arg_val = 1 if arg[1] is True else 0
            bytecode += "{0:0{1}x}".format(int(arg_val), 64)
        elif arg_type == "address":
            bytecode += arg_val.strip("0x").zfill(64)
        else:
            print(
                "Error: Invalid argument type '{}' given at "
                "'calculate_bytecode()`".format(arg_type)
            )
            sys.exit(1)
    return bytecode


def available_scenarios():
    dir = "scenarios"
    return [name for name in os.listdir(dir)
            if os.path.isdir(os.path.join(dir, name))]


def to_wei(val_in_ether):
    return val_in_ether * 1000000000000000000
