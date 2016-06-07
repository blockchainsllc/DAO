var dao_abi = $dao_abi;
var dao = web3.eth.contract(dao_abi).at('$dao_address');
var split_execution_period = $split_execution_period;
var new_curator = eth.accounts[1];

var prop_id = attempt_proposal(
    dao, // DAO in question
    new_curator, // recipient
    new_curator, // proposal creator
    0, // proposal amount in ether
    'Our disgruntled user wants to split out', // description
    '', //bytecode
    $debating_period, // debating period
    0, // proposal deposit in ether
    true // whether it's a split proposal or not
);

console.log("Voting for split proposal '" + prop_id + "' ...");
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        prop_id,
        i == 1 ? true : false,
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}
checkWork();
addToTest('proposal_yay', parseInt(web3.fromWei(dao.proposals(prop_id)[9])));
addToTest('proposal_nay', parseInt(web3.fromWei(dao.proposals(prop_id)[10])));

setTimeout(function() {
    miner.stop();
    // now our disgruntled user is the only one to execute the splitDAO function
    attempt_split(dao, prop_id, new_curator, new_curator, split_execution_period);

    console.log("After split execution");
    addToTest('proposal_passed', dao.proposals(prop_id)[5]);
    addToTest('proposal_newdao', dao.splitProposalNewAddress(prop_id, 0));

    var newdao = web3.eth.contract(dao_abi).at(testMap['proposal_newdao']);
    // check token balance of each user in both DAOs
    oldDAOBalance = [];
    newDAOBalance = [];
    for (i = 0; i < eth.accounts.length; i++) {
        oldDAOBalance.push(parseInt(web3.fromWei(dao.balanceOf(eth.accounts[i]))));
        newDAOBalance.push(parseInt(web3.fromWei(newdao.balanceOf(eth.accounts[i]))));
    }
    addToTest('oldDAOBalance', oldDAOBalance);
    addToTest('newDAOBalance', newDAOBalance);
    addToTest('newDAOTotalSupply', parseInt(web3.fromWei(newdao.totalSupply())));

    setTimeout(function() {
        console.log("MINQUORUM REQUIRED: " + newdao.extMinQuorum(newdao.totalSupply()));
        // now our disgruntled user has his own DAO and is the SP of that DAO so ...
        var new_prop_id = attempt_proposal(
            newdao, // DAO in question
            new_curator, // recipient
            new_curator, // proposal creator
            testMap['newDAOTotalSupply'], // proposal amount in ether
            'Send all money to myself!! Screw you guys ... I am going home!', // description
            '', //bytecode
            $debating_period, // debating period
            $proposal_deposit, // proposal deposit in ether
            false // whether it's a split proposal or not
        );

        console.log("Angry user votes in his own DAO...");
        newdao.vote.sendTransaction(
            new_prop_id,
            true,
            {
                from: new_curator,
                gas: 1000000
            });
        checkWork();
        addToTest('newdao_proposals_num', newdao.numberOfProposals());
        addToTest('angry_user_before', web3.fromWei(eth.getBalance(new_curator)));
        setTimeout(function() {
            // now execute the proposal
            attempt_execute_proposal(
                newdao, // target DAO
                new_prop_id, // proposal ID
                new_curator, // proposal creator
                true, // should the proposal be closed after this call?
                true // should the proposal pass?
            );

            addToTest('angry_user_after', web3.fromWei(eth.getBalance(new_curator)));
            addToTest(
                'angry_user_profit',
                bigDiffRound(testMap['angry_user_after'], testMap['angry_user_before'])
            );
            testResults();
        }, $debating_period * 1000);
        console.log("Wait for end of second debating period");
    }, split_execution_period * 1000);
    console.log("Wait for new DAO fueling period to end");
}, $debating_period * 1000);
console.log("Wait for end of first debating period");
