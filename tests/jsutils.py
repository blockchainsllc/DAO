#!/usr/bin/python2


def js_common_intro(accounts_num):
    """Common  functions, variables to add to all js scripts"""
    s = "console.log('unlocking accounts');\n"
    for i in range(0, accounts_num):
        s += "personal.unlockAccount(eth.accounts[{}], '123');\n".format(i)
    s += """// set the basic accounts, coinbase should be random so mining rewards don't pollute results
var curator = eth.accounts[0];
var proposalCreator = eth.accounts[1];
var contractor = eth.accounts[2];
var etherBase = '0x9999999999999999999999999999999999999999';
web3.miner.setEtherbase(etherBase);

var testMap = {};

function checkWork() {
    miner.start(1);
    admin.sleepBlocks(3);
    miner.stop();
}

function time_now() {
    return Math.floor(Date.now() / 1000);
}

function bigDiff(astr, bstr) {
    return new BigNumber(astr).minus(new BigNumber(bstr));
}

function bigDiffRound(astr, bstr) {
    return Math.round(bigDiff(astr, bstr));
}

function addToTest(name, value) {
    testMap[name] = value;
    console.log("'" + name + "' = " + value);
}

function testResults() {
    console.log("Test Results: " + JSON.stringify(testMap));
}

function testFail(str) {
    console.log("TEST FAIL: " + str);
    throw ' ';
}

function attempt_proposal(
    argdao,
    recipient,
    proposal_creator,
    ether_amount,
    desc,
    bytecode,
    debating_period,
    ether_deposit,
    is_split_proposal
    ) {

    dao_closing_time = argdao.closingTime();

    if (!argdao.isFueled()) {
        testFail(
            "Failed to create a proposal to: '" + desc + "' because the DAO "
            + "is not fueled."
        );
    }
    if (dao_closing_time.gt(time_now())) {
        testFail(
            "Failed to create a proposal to: '" + desc + "' because the DAO's "
            + "creation time has not yet closed.\\ndao_closing_time: "
            + dao_closing_time + "\\nnow(): " + time_now()
        );
    }
    proposals_num_before = argdao.numberOfProposals();
    console.log("Creating a new proposal to: '" + desc + "'");
    argdao.newProposal.sendTransaction(
    recipient,
    web3.toWei(ether_amount, "ether"),
    desc,
    bytecode,
    debating_period,
    is_split_proposal,
    {
        from: proposal_creator,
        value: web3.toWei(ether_deposit, "ether"),
        gas: 1000000
    });
    checkWork();
    proposals_num_now = argdao.numberOfProposals();

    if (!proposals_num_now.equals(proposals_num_before.add(1))) {
        testFail("Failed to create a proposal to: " + desc + "'");
    } else {
        console.log("Proposal succesfully created");
    }
    return proposals_num_now;
}

function attempt_split(argdao, prop_id, user, new_curator, split_exec_period) {
    console.log("Account '" + user + "' is calling splitDAO()");
    var vote_deadline = argdao.proposals(prop_id)[3];
    if (vote_deadline.gt(time_now())) {
        testFail("Can't split the DAO while the proposal is still debated.");
    }
    var prop_deadline = vote_deadline.add(split_exec_period);
    console.log("prop_deadline: " + prop_deadline);
    console.log("now(): " + time_now());
    if (prop_deadline.lessThan(time_now() + 5)) {
        testFail("Can no longer vote to split the DAO. 'now > p.votingDeadline + splitExecutionPeriod'");
    }
    argdao.splitDAO.sendTransaction(
        prop_id,
        new_curator,
        {from:user, gas: 4700000});
    checkWork();
    console.log("Account '" + user + "' called splitDAO() succesfully");
}

function attempt_execute_proposal(
    argdao,
    prop_id,
    bytecode,
    prop_creator,
    expect_closed,
    expect_pass) {
    desc = argdao.proposals(prop_id)[2];
    vote_deadline = argdao.proposals(prop_id)[3];
    console.log("Attempting to execute proposal for: '" +desc +"'.");

    if (vote_deadline.gt(time_now())) {
        testFail("Can't execute a proposal while it is is still debated.");
    }

    argdao.executeProposal.sendTransaction(
        prop_id,
        bytecode,
        {from: prop_creator, gas:4700000}
    );
    checkWork();
    var should_quit = false;
    if (argdao.proposals(prop_id)[4] == expect_closed) {
        should_quit = true;
        console.log(
            "Expected the proposal to be " + (expect_closed ? "closed" : "open") +
            " but it's not"
        );
    }
    if (argdao.proposals(prop_id)[5] != expect_pass) {
        should_quit = true;
        console.log(
            "Expected the proposal for: '" +desc +" to " +
            (expect_pass ? "pass" : "fail") + "."
        );
    }
    if (should_quit) {
        testFail("Failed to execute proposal for: '" +desc +"'.");
    }
    console.log("Executed proposal: '" + desc + "'.");
}
"""
    return s
