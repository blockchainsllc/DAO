var dao = web3.eth.contract($dao_abi).at('$dao_address');
var offer = web3.eth.contract($offer_abi).at('$offer_address');

var prop_id = attempt_proposal(
    dao, // DAO in question
    '$offer_address', // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Give us back our money!', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);

var bad_prop_id = attempt_proposal(
    dao, // DAO in question
    '$offer_address', // recipient
    proposalCreator, // proposal creator
    10, // proposal amount in ether
    'Give us back our money - bad!', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);


console.log("Voting for the proposal to fire the contractor");
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        prop_id,
        true, //omg it's unanimous!
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
    dao.vote.sendTransaction(
        bad_prop_id,
        true, //omg it's unanimous!
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}
checkWork();
var offer_balance_before =  eth.getBalance(offer.address);
var dao_rewardaccount_before = eth.getBalance(dao.DAOrewardAccount());

setTimeout(function() {
    miner.stop();
    console.log("After debating period. NOW is: " + Math.floor(Date.now() / 1000));
    // first of all attempt to execute the proposal that sneaks in a value
    attempt_execute_proposal(
        dao, // target DAO
        bad_prop_id, // proposal ID
        proposalCreator, // proposal creator
        false, // should the proposal be closed after this call?
        false // should the proposal pass?
    );
    var offer_balance_after =  eth.getBalance(offer.address);
    addToTest('bad_proposal_failed', offer_balance_after.eq(offer_balance_before));
    // addToTest('bad_proposal_failed', true);
    addToTest('after_bad_proposal_offer_has', web3.fromWei(eth.getBalance(offer.address)));
    addToTest('after_bad_contract_valid', offer.getIsContractValid());

    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        proposalCreator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );

    offer_balance_after = eth.getBalance(offer.address);
    var dao_rewardaccount_after = eth.getBalance(dao.DAOrewardAccount());

    var offer_diff = offer_balance_after.sub(offer_balance_before);
    var rewards_diff = dao_rewardaccount_before.sub(dao_rewardaccount_after);

    addToTest('got_back_all_money', rewards_diff.eq(offer_diff));
    addToTest('offer_contract_valid', offer.getIsContractValid());

    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
miner.start(1);
