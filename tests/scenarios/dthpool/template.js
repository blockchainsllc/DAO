var dao = web3.eth.contract($dao_abi).at('$dao_address');
var dthpool = web3.eth.contract($dthpool_abi).at('$dthpool_address');

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
        if (actions[idx].action === "Aprobe") {
            console.log("Aprobe Step: " + actions[idx].step);
            dao.approve.sendTransaction( dthpool.address , web3.toWei(actions[idx].amount), {from: eth.accounts[actions[idx].account], gas: 1000000}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "Delegate") {
            console.log("Delegating step: " + actions[idx].step);
            dthpool.delegateDAOTokens.sendTransaction( web3.toWei(actions[idx].amount) , {from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "CreateProposal") {
            console.log("Creating Proposal: " + actions[idx].step);
            dao.newProposal.sendTransaction(eth.accounts[0], web3.toWei(20,'ether'), "proposal1", 0, 60, false, {from: eth.accounts[0], gas: 1000000, value: web3.toWei(25,'ether')}, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "SetVoteIntention") {
            console.log("Set vote intention step: " + actions[idx].step);
            dthpool.setVoteIntention.sendTransaction( actions[idx].proposal , actions[idx].willVote , actions[idx].supportsProposal, "test motivation", {from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "executeAllVotes") {
            console.log("Set executeAllVotes step: " + actions[idx].step);
            dthpool.executeAllVotes.sendTransaction({from: eth.accounts[actions[idx].account], gas: 1000000  }, function(err) {
                if (err) return endAction(err);
                waitBlock(endAction);
            });
        } else if (actions[idx].action === "Wait") {
            console.log("Waiting step: " + actions[idx].step);
            waitTime(actions[idx].time, endAction);
        }
    };

    var idx =-1;
    endAction();
}


var steps = [
    { step: 1, action:"Aprobe", account: 0, amount: 2},
    { step: 2, action:"Delegate", account: 0 , amount: 2, test: function() {
        addToTest("notDelegated",web3.fromWei(dao.balanceOf(eth.accounts[0])));
        addToTest("delegated",web3.fromWei(dthpool.balanceOf(eth.accounts[0])));
    }},
    { step: 3, action:"CreateProposal", account: 1 , proposal: 1, supports: false},
    { step: 4, action:"SetVoteIntention", account: 0 , proposal: 1, willVote: true, supportsProposal: true, test: function() {
//        console.log("Res: ", dthpool.res());
//        console.log("Voting Dead Line: ", dthpool.vdl());
//        console.log("New Curator: ", dthpool.nc());
//        console.log("Now: ", dthpool.n());
        addToTest( "voteSet1", dthpool.proposalStatuses(1)[0]);
        addToTest( "willVote1", dthpool.proposalStatuses(1)[1]);
        addToTest( "supportsProposal1", dthpool.proposalStatuses(1)[2]);
        addToTest( "executed1", dthpool.proposalStatuses(1)[3]);
    }},
    { step: 5, action:"Wait", time: 30},
    { step: 6, action:"executeAllVotes", account: 1 ,proposal: 1, test: function() {
        addToTest('y6' , parseInt(web3.fromWei(dao.proposals(1)[9])));
        addToTest('n6' , parseInt(web3.fromWei(dao.proposals(1)[10])));
    }}

];

miner.start(2);

run(steps, function() {
    filter.stopWatching();
    testResults();
    miner.stop();
});

console.log("Executing steps");

