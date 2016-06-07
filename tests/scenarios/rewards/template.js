var dao = web3.eth.contract($dao_abi).at('$dao_address');

// some kind soul makes a donation to the DAO, so rewards get populated
console.log("Donating to DAO...");
eth.sendTransaction({
    from:eth.accounts[1],
    to: dao.DAOrewardAccount(),
    gas: 210000,
    value: web3.toWei($total_rewards, "ether")
});
checkWork();

var prop_id = attempt_proposal(
    dao, // DAO in question
    dao.address, // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Ask the DAO to retrieveDAOReward()', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit + 1, // proposal deposit in ether
    false // whether it's a split proposal or not
);

console.log("Voting for proposal '" + prop_id + "' ...");
// in this scenario let's just say everyone votes 100% in favour
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        prop_id,
        true,
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}
checkWork();

setTimeout(function() {
    miner.stop();

    // now execute the proposal
    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        curator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );

    addToTest('curator_balance_before_claim', eth.getBalance(curator));
    console.log("Claiming the reward...");
    dao.getMyReward.sendTransaction({from: curator, gas: 1000000});
    checkWork();
    addToTest('curator_balance_after_claim', eth.getBalance(curator));
    addToTest(
        'curator_reward_portion',
        parseFloat(web3.fromWei(bigDiff(
            testMap['curator_balance_after_claim'], testMap['curator_balance_before_claim']
        )))
    );
    addToTest('DAO_balance', parseFloat(web3.fromWei(eth.getBalance('$dao_address'))));
    addToTest('DAO_rewardToken', parseFloat(web3.fromWei(dao.rewardToken('$dao_address'))));
    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
