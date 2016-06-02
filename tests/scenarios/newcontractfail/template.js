var dao = web3.eth.contract($dao_abi).at('$dao_address');

// No need to have an actual contract for the purpose of the test
var newContract = '$new_contract_address';
addToTest('new_contract_balance_before', web3.fromWei(eth.getBalance(newContract)));
addToTest('dao_balance_before', web3.fromWei(eth.getBalance(dao.address)));
console.log("Add new contract as allowed recipient");
dao.changeAllowedRecipients.sendTransaction(newContract, true, {from: curator, gas: 1000000});
checkWork();

var prop_id = attempt_proposal(
    dao, // DAO in question
    dao.address, // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Move all funds to a new contract', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);

console.log("Vote on the proposal to update");
var votes = $votes;
for (i = 0; i < votes.length; i++) {
    dao.vote.sendTransaction(
        prop_id,
        votes[i],
        {
            from: eth.accounts[i],
            gas: 4000000
        }
    );
}
checkWork();

setTimeout(function() {
    miner.stop();
    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        curator, // proposal creator
        false, // should the proposal be closed after this call?
        false // should the proposal pass?
    );

    addToTest('new_contract_balance_after', web3.fromWei(eth.getBalance(newContract)));
    addToTest('new_contract_balance', bigDiff(
        testMap['new_contract_balance_after'],
        testMap['new_contract_balance_before']
    ));
    addToTest('dao_balance_after', web3.fromWei(eth.getBalance(dao.address)));
    addToTest('dao_balance_diff', bigDiff(
        testMap['dao_balance_after'],
        testMap['dao_balance_before']
    ));

    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
miner.start(1);
