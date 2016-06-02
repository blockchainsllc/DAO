var dao = web3.eth.contract($dao_abi).at('$dao_address');

// No need to have an actual contract for the purpose of the test
var newContract = '$new_contract_address';
addToTest('new_contract_balance_before', web3.fromWei(eth.getBalance(newContract)));
addToTest('dao_balance_before', web3.fromWei(eth.getBalance(dao.address)));
addToTest('dao_reward_token_before', web3.fromWei(dao.rewardToken(dao.address)));
addToTest('new_contract_reward_token_before', web3.fromWei(dao.rewardToken(newContract)));
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
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        prop_id,
        true,
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
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );

    addToTest('new_contract_balance_after', web3.fromWei(eth.getBalance(newContract)));
    addToTest('dao_balance_after', web3.fromWei(eth.getBalance(dao.address)));
    addToTest('dao_reward_token_after', web3.fromWei(dao.rewardToken(dao.address)));
    addToTest('new_contract_reward_token_after', web3.fromWei(dao.rewardToken(newContract)));

    addToTest('new_contract_balance', bigDiff(
        testMap['new_contract_balance_after'],
        testMap['new_contract_balance_before']
    ));
    addToTest(
        'money_transferred',
        testMap['new_contract_balance'].ceil().equals(testMap['dao_balance_before'].ceil())
    );
    addToTest(
        'reward_tokens_transferred',
        testMap['new_contract_reward_token_after'].ceil().equals(testMap['dao_reward_token_before'].ceil())
    );


    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
miner.start(1);
