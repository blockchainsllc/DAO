var dao = web3.eth.contract($dao_abi).at('$dao_address');
var prop_id = attempt_proposal(
    dao, // DAO in question
    dao.address, // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Changing proposal deposit', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);

// in this scenario all users vote for the change
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
    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        curator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );

    addToTest('deposit_after_vote', parseInt(dao.proposalDeposit()));
    testResults();
}, $debating_period * 1000);
miner.start(1);
