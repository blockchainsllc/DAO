var dao = web3.eth.contract($dao_abi).at('$dao_address');
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
            dao.executeProposal.sendTransaction( actions[idx].proposal , data_newDefaultDelegate, {from: eth.accounts[1], gas: 4000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "W") {
            console.log("Waiting step: " + actions[idx].step);
            waitTime(actions[idx].time, endAction);
        } else if (actions[idx].action === "S") {
            console.log("Exec split: " + actions[idx].step);
            dao.splitDAO.sendTransaction( 5 , eth.accounts[1], {from: eth.accounts[actions[idx].account], gas: 4710000  }, function(err) {
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
    { step: 33, action:"V", account: 0 , proposal: 5, supports: true},
    { step: 34, action:"V", account: 5 , proposal: 5, supports: true},
    { step: 35, action:"W", time: 120},
    { step: 36, action:"S", account: 1, proposal: 5, test: function() {
        addToTest( "s36_tokenholder_votes_1_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],5)[0])));
        addToTest( "s36_tokenholder_votes_1_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[1],6)[0])));
        addToTest( "s36_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s36_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s36_delegated_votes_1_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[1],5))));
        addToTest( "s36_delegated_votes_1_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[1],6))));
    }},
    { step: 37, action:"S", account: 0, proposal: 5, test: function() {
        addToTest( "s37_tokenholder_votes_0_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[0],5)[0])));
        addToTest( "s37_tokenholder_votes_0_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[0],6)[0])));
        addToTest( "s37_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s37_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s37_delegated_votes_0_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],5))));
        addToTest( "s37_delegated_votes_0_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[0],6))));
    }},
    { step: 38, action:"S", account: 4, proposal: 5, test: function() {
        addToTest( "s38_tokenholder_votes_4_before",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[4],5)[0])));
        addToTest( "s38_tokenholder_votes_4_after",  parseInt(web3.fromWei(dao.getTokenHolderVotingRights(eth.accounts[4],6)[0])));
        addToTest( "s38_delegated_votes_def_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,5))));
        addToTest( "s38_delegated_votes_def_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(0,6))));
        addToTest( "s38_delegated_votes_5_before",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],5))));
        addToTest( "s38_delegated_votes_5_after",  parseInt(web3.fromWei(dao.getDelegateVotingRights(eth.accounts[5],6))));
    }},
    { step: 39, action:"W", time: 10}
];

miner.start(2);

run(steps, function() {
    filter.stopWatching();
    testResults();
    miner.stop();
});

console.log("Wait for end of debating period");

