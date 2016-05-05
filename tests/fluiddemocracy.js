console.log('unlocking accounts');
personal.unlockAccount(eth.accounts[0], '123', 1800);
personal.unlockAccount(eth.accounts[1], '123', 1800);
personal.unlockAccount(eth.accounts[2], '123', 1800);
personal.unlockAccount(eth.accounts[3], '123', 1800);
personal.unlockAccount(eth.accounts[4], '123', 1800);
personal.unlockAccount(eth.accounts[5], '123', 1800);
// set the basic accounts, coinbase should be random so mining rewards don't pollute results
var curator = eth.accounts[0];
var proposalCreator = eth.accounts[1];
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
            + "creation time has not yet closed.\ndao_closing_time: "
            + dao_closing_time + "\nnow(): " + time_now()
        );
    }
    proposals_num_before = argdao.numberOfProposals();
    console.log("Creating a new proposal to: '" + desc + "'");
    console.log("recipient: " + recipient);
    console.log("amount: " + web3.toWei(ether_amount, "ether"));
    console.log("desc: " + desc);
    console.log("bytecode: " + bytecode);
    console.log("debating_period: " + debating_period);
    console.log("is_split_proposal: " + is_split_proposal);
    console.log("from: " + proposal_creator);
    console.log("value: " + web3.toWei(ether_deposit, "ether"));
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
        testFail("Can't execute a proposal whilte it is is still debated.");
    }

    argdao.executeProposal.sendTransaction(
        prop_id,
        bytecode,
        {from: prop_creator, gas:4700000}
    );
    checkWork();
    if (argdao.proposals(prop_id)[4] == expect_closed) {
        testFail(
            "Failed to execute proposal for: '" +desc +"'. Expected the " +
            "proposal to be " + (expect_closed ? "closed" : "open") +
            " but it's not"
        );
    }
    if (argdao.proposals(prop_id)[5] != expect_pass) {
        testFail(
            "Expected the proposal for: '" +desc +" to " +
            (expect_pass ? "pass" : "fail") + "."
        );
    }
    console.log("Executed proposal: '" + desc + "'.");
}

var dao = web3.eth.contract([{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"proposals","outputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"},{"name":"description","type":"string"},{"name":"votingDeadline","type":"uint256"},{"name":"open","type":"bool"},{"name":"proposalPassed","type":"bool"},{"name":"proposalHash","type":"bytes32"},{"name":"proposalDeposit","type":"uint256"},{"name":"newCurator","type":"bool"},{"name":"yea","type":"uint256"},{"name":"nay","type":"uint256"},{"name":"creator","type":"address"}],"type":"function"},{"constant":true,"inputs":[{"name":"pid","type":"uint256"},{"name":"sid","type":"uint256"}],"name":"splitProposalNewAddress","outputs":[{"name":"_DAO","type":"address"}],"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"minTokensToCreate","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"rewardAccount","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[{"name":"_tokenHolder","type":"address"},{"name":"_proposalID","type":"uint256"}],"name":"getTokenHolderVotingRights","outputs":[{"name":"votes","type":"uint256"},{"name":"delegate","type":"address"}],"type":"function"},{"constant":true,"inputs":[],"name":"daoCreator","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"divisor","outputs":[{"name":"divisor","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"extraBalance","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":false,"inputs":[{"name":"_proposalID","type":"uint256"},{"name":"_transactionData","type":"bytes"}],"name":"executeProposal","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalRewardToken","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"actualBalance","outputs":[{"name":"_actualBalance","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_newDefaultDelegate","type":"address"}],"name":"newDefaultDelegate","outputs":[],"type":"function"},{"constant":true,"inputs":[],"name":"closingTime","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"allowedRecipients","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferWithoutReward","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"pid","type":"uint256"},{"name":"sid","type":"uint256"}],"name":"splitProposalBalance","outputs":[{"name":"_balance","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"type":"function"},{"constant":true,"inputs":[{"name":"_delegate","type":"address"},{"name":"_proposalID","type":"uint256"}],"name":"getDelegateVotingRights","outputs":[{"name":"votes","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_recipient","type":"address"},{"name":"_amount","type":"uint256"},{"name":"_description","type":"string"},{"name":"_transactionData","type":"bytes"},{"name":"_debatingPeriod","type":"uint256"},{"name":"_newCurator","type":"bool"}],"name":"newProposal","outputs":[{"name":"_proposalID","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"DAOpaidOut","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"minQuorumDivisor","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_newContract","type":"address"}],"name":"newContract","outputs":[],"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_recipient","type":"address"},{"name":"_allowed","type":"bool"}],"name":"changeAllowedRecipients","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":false,"inputs":[],"name":"halveMinQuorum","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"paidOut","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_proposalID","type":"uint256"},{"name":"_newCurator","type":"address"}],"name":"splitDAO","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"DAOrewardAccount","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[],"name":"proposalDeposit","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"numberOfProposals","outputs":[{"name":"_numberOfProposals","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"lastTimeMinQuorumMet","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_toMembers","type":"bool"}],"name":"retrieveDAOReward","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"_val","type":"uint256"}],"name":"extMinQuorum","outputs":[{"name":"_minQuorum","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"receiveEther","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"isFueled","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"_tokenHolder","type":"address"}],"name":"createTokenProxy","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"_proposalID","type":"uint256"}],"name":"getNewDAOAddress","outputs":[{"name":"_newDAO","type":"address"}],"type":"function"},{"constant":false,"inputs":[{"name":"_proposalID","type":"uint256"},{"name":"_supportsProposal","type":"bool"}],"name":"vote","outputs":[{"name":"_voteID","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_delegate","type":"address"}],"name":"setDelegate","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[],"name":"getMyReward","outputs":[{"name":"_success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"rewardToken","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"pid","type":"uint256"},{"name":"sid","type":"uint256"}],"name":"splitProposalrewardToken","outputs":[{"name":"_rewardToken","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"pid","type":"uint256"},{"name":"sid","type":"uint256"}],"name":"splitProposalSupply","outputs":[{"name":"_supply","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFromWithoutReward","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_proposalDeposit","type":"uint256"}],"name":"changeProposalDeposit","outputs":[],"type":"function"},{"constant":true,"inputs":[],"name":"curator","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[{"name":"_proposalID","type":"uint256"},{"name":"_recipient","type":"address"},{"name":"_amount","type":"uint256"},{"name":"_transactionData","type":"bytes"}],"name":"checkProposalCode","outputs":[{"name":"_codeChecksOut","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"privateCreation","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[],"name":"defaultDelegate","outputs":[{"name":"","type":"address"}],"type":"function"},{"inputs":[{"name":"_curator","type":"address"},{"name":"_defaultDelegate","type":"address"},{"name":"_daoCreator","type":"address"},{"name":"_proposalDeposit","type":"uint256"},{"name":"_minTokensToCreate","type":"uint256"},{"name":"_closingTime","type":"uint256"},{"name":"_privateCreation","type":"address"}],"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"value","type":"uint256"}],"name":"FuelingToDate","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"CreatedToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Refund","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"newCurator","type":"bool"},{"indexed":false,"name":"description","type":"string"}],"name":"ProposalAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"position","type":"bool"},{"indexed":true,"name":"voter","type":"address"}],"name":"Voted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"result","type":"bool"},{"indexed":false,"name":"quorum","type":"uint256"}],"name":"ProposalTallied","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_newCurator","type":"address"}],"name":"NewCurator","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_newDefaultDelegate","type":"address"}],"name":"NewDefaultDelegate","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_recipient","type":"address"},{"indexed":false,"name":"_allowed","type":"bool"}],"name":"AllowedRecipientChanged","type":"event"}]).at('0x4557c8c016e477b31e962242f7f5b4039fbd95f8');
dao.changeAllowedRecipients.sendTransaction(eth.accounts[1], true, {from: curator, gas: 1000000});

checkWork();

var filter = web3.eth.filter('latest');

var pendingWaits = [];
filter.watch(function (error, blockHash) {
    var block = eth.getBlock(blockHash);
    bn = block.number;

    var i=0;
    while (i<pendingWaits.length) {
        var cur = pendingWaits[i];
        if (((cur.block) && (cur.block<=bn) && ((new Date()).getTime() > cur.time )) ||
            ((cur.time) && (!cur.block) && ((new Date()).getTime() > cur.time )))
         {
            var last  = pendingWaits.pop();
            if (last !== cur) {
                pendingWaits[i] = last;
            }
            cur.cb();
        } else {
            i+=1;
        }
    }
});

function waitBlock(cb) {
    var pendingWait = {
        block: eth.blockNumber + 6,
        time: (new Date()).getTime() + 5*1000,
        cb: cb
    };
    pendingWaits.push(pendingWait);
}

function waitTime(t, cb) {
    var pendingWait = {
        time: (new Date()).getTime() + t*1000,
        cb: cb
    };
    pendingWaits.push(pendingWait);
}


var data_newDefaultDelegate;

function run(actions, cb) {

    var endAction = function(err, res) {
        if (idx >=0) {
            if (err) {
                console.log("Error in step: " + idx + "err:" + err);
                return cb(err);
            }
            if (actions[idx].action==="V") {
                addToTest('y' + actions[idx].step, parseInt(web3.fromWei(dao.proposals(actions[idx].proposal)[9])));
                addToTest('n' + actions[idx].step, parseInt(web3.fromWei(dao.proposals(actions[idx].proposal)[10])));
            }
            if (typeof actions[idx].test === "function") {
                actions[idx].test(actions[idx]);
            }
        }
        idx += 1;
        if (idx == actions.length) {
            return cb();
        }
        exec_pos(idx);
    };


    var exec_pos = function(idx) {
        if (actions[idx].action === "V") {
            console.log("Voting Step: " + actions[idx].step);
            dao.vote.sendTransaction(actions[idx].proposal, actions[idx].supports, {from: eth.accounts[actions[idx].account], gas: 1000000}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if ((actions[idx].action === "P")&&(actions[idx].proposal === 3)) {
            console.log("Creating Proposal newDefaultDelegate: " + actions[idx].step);
            data_newDefaultDelegate = dao.newDefaultDelegate.getData(eth.accounts[1]);
            dao.newProposal.sendTransaction(dao.address, 0, "newDefaultDelegate", data_newDefaultDelegate, 120, false, {from: eth.accounts[0], gas: 1000000, value: web3.toWei(25,'ether')}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if ((actions[idx].action === "P")&&(actions[idx].proposal === 5)) {
            console.log("Creating Proposal split: " + actions[idx].step);
            data_newDefaultDelegate = dao.newDefaultDelegate.getData(eth.accounts[1]);
            dao.newProposal.sendTransaction(eth.accounts[1], 0, "splitProposal", 0, 120, true, {from: eth.accounts[1], gas: 1000000}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "P") {
            console.log("Creating Proposal: " + actions[idx].step);
            dao.newProposal.sendTransaction(eth.accounts[0], web3.toWei(20,'ether'), "proposal1", 0, 3600, false, {from: eth.accounts[0], gas: 1000000, value: web3.toWei(25,'ether')}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "D") {
            console.log("Delegating step: " + actions[idx].step);
            dao.setDelegate.sendTransaction( eth.accounts[ actions[idx].delegate] , {from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "T") {
            console.log("Transfer step: " + actions[idx].step);
            dao.transfer.sendTransaction( eth.accounts[ actions[idx].to] , web3.toWei(actions[idx].value), {from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "E") {
            console.log("Exec step: " + actions[idx].step);
            dao.executeProposal.sendTransaction( actions[idx].proposal , data_newDefaultDelegate, {from: eth.accounts[1], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "W") {
            console.log("Waiting step: " + actions[idx].step);
            waitTime(actions[idx].time, endAction);
        } else if (actions[idx].action === "S") {
            console.log("Exec split: " + actions[idx].step);
            dao.splitDAO.sendTransaction( 5 , eth.accounts[1], {from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        }

    };

    var idx =-1;
    endAction();
}


var steps = [
    { step: 1, action:"P", proposal: 1},
    { step: 2, action:"V", account: 0 , proposal: 1, supports: true},
    { step: 3, action:"V", account: 1 , proposal: 1, supports: false},
    { step: 4, action:"V", account: 2 , proposal: 1, supports: true},
    { step: 5, action:"V", account: 3 , proposal: 1, supports: false},
    { step: 6, action:"V", account: 4 , proposal: 1, supports: false},
    { step: 7, action:"V", account: 5 , proposal: 1, supports: false},
    { step: 8, action:"V", account: 0 , proposal: 1, supports: false},
    { step: 9, action:"D", account: 2 , delegate: 5},
    { step: 10, action:"D", account: 3 , delegate: 5, test: function() {
        addToTest( "s10_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,1))));
        addToTest( "s10_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,2))));
        addToTest( "s10_delegated_votes_0_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],1))));
        addToTest( "s10_delegated_votes_0_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],2))));
        addToTest( "s10_delegated_votes_5_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],1))));
        addToTest( "s10_delegated_votes_5_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],2))));
    }},
    { step: 11, action:"P", proposal: 2},
    { step: 12, action:"V", account: 5 , proposal: 2, supports: true},
    { step: 13, action:"V", account: 2 , proposal: 2, supports: false},
    { step: 14, action:"V", account: 3 , proposal: 2, supports: false},
    { step: 15, action:"V", account: 0 , proposal: 2, supports: true},
    { step: 16, action:"V", account: 4 , proposal: 2, supports: false},
    { step: 17, action:"P", proposal: 3},
    { step: 18, action:"T", account: 3, to: 5, value: 5, test: function() {
        addToTest( "s18_tokenholder_votes_3_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[3],3)[0])));
        addToTest( "s18_tokenholder_votes_3_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[3],4)[0])));
        addToTest( "s18_tokenholder_votes_5_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[5],3)[0])));
        addToTest( "s18_tokenholder_votes_5_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[5],4)[0])));
        addToTest( "s18_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,3))));
        addToTest( "s18_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,4))));
        addToTest( "s18_delegated_votes_5_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],3))));
        addToTest( "s18_delegated_votes_5_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],4))));
    }},
    { step: 19, action:"V", account: 1, proposal: 3, supports: true},
    { step: 20, action:"T", account: 1, to: 5, value: 7, test: function() {
        addToTest( "s20_tokenholder_votes_1_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],3)[0])));
        addToTest( "s20_tokenholder_votes_1_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],4)[0])));
        addToTest( "s20_tokenholder_votes_5_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[5],3)[0])));
        addToTest( "s20_tokenholder_votes_5_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[5],4)[0])));
        addToTest( "s20_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,3))));
        addToTest( "s20_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,4))));
        addToTest( "s20_delegated_votes_5_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],3))));
        addToTest( "s20_delegated_votes_5_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],4))));
    }},
    { step: 21, action:"V", account: 3 , proposal: 3, supports: true},
    { step: 22, action:"V", account: 5 , proposal: 3, supports: false},
    { step: 23, action:"D", account: 4 , delegate: 5},
    { step: 24, action:"P", proposal: 4},
    { step: 25, action:"V", account: 4 , proposal: 3, supports: true},
    { step: 26, action:"V", account: 5 , proposal: 4, supports: true},
    { step: 27, action:"V", account: 0 , proposal: 4, supports: false},
    { step: 28, action:"W", time: 120},
    { step: 29, action:"E", proposal: 3},
    { step: 30, action:"V", account: 1 , proposal: 4, supports: true},
    { step: 31, action:"P", proposal: 5},
    { step: 32, action:"V", account: 1 , proposal: 5, supports: true},
    { step: 33, action:"V", account: 2 , proposal: 5, supports: true},
    { step: 34, action:"W", time: 120},
    { step: 35, action:"S", account: 1, proposal: 5, test: function() {
        addToTest( "s35_tokenholder_votes_1_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],5)[0])));
        addToTest( "s35_tokenholder_votes_1_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],6)[0])));
        addToTest( "s35_delegate_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s35_delegate_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s35_delegate_votes_1_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[1],5))));
        addToTest( "s35_delegate_votes_1_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[1],6))));
    }},
    { step: 36, action:"S", account: 0, proposal: 5, test: function() {
        addToTest( "s36_tokenholder_votes_0_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[0],5)[0])));
        addToTest( "s36_tokenholder_votes_0_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[0],6)[0])));
        addToTest( "s36_delegate_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s36_delegate_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s36_delegate_votes_0_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],5))));
        addToTest( "s36_delegate_votes_0_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],6))));
    }},
    { step: 37, action:"S", account: 4, proposal: 5, test: function() {
        addToTest( "s36_tokenholder_votes_4_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[4],5)[0])));
        addToTest( "s36_tokenholder_votes_4_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[4],6)[0])));
        addToTest( "s36_delegate_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s36_delegate_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s36_delegate_votes_5_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],5))));
        addToTest( "s36_delegate_votes_5_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],6))));
    }}

];

miner.start();

run(steps, function() {
    filter.stopWatching();
    testResults();
    miner.stop();
});

console.log("Wait for end of debating period");

