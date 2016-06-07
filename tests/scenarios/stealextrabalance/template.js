var dao = web3.eth.contract($dao_abi).at('$dao_address');
var attacker = '$attacker_address';
var extraBalance = dao.extraBalance();

addToTest('extra_balance_before', web3.fromWei(eth.getBalance(extraBalance)));

var claim_prop_id = attempt_proposal(
    dao, // DAO in question
    extraBalance, // recipient
    attacker, // proposal creator
    0, // proposal amount in ether
    'Ask the extraBalance account to pay out to the DAO', // description
    '$transaction_bytecode', // transaction bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);
console.log("Voting on the extra balance attack payout proposal");
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        claim_prop_id,
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
    console.log("After extra balance payout attack debating period");
    attempt_execute_proposal(
        dao, // target DAO
        claim_prop_id, // proposal ID
        attacker, // proposal creator
        false, // should the proposal be closed after this call?
        false // should the proposal pass?
    );

    addToTest('extra_balance_after', web3.fromWei(eth.getBalance(extraBalance)));
    addToTest('extra_balance_diff_after_attack',
              testMap['extra_balance_after'].sub(
                  testMap['extra_balance_before']
              ).round());

    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period for claiming extraBalance payout attack");
miner.start(1);

