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

console.log("TEST - proposal check: " + dao.checkProposalCode(
    prop_id,
    offer.address,
    0,
    "0xbf51f24d0000000000000000000000000000000000000000000000000000000000000002"
));
console.log("TEST2 - proposal hash " + dao.proposals(prop_id)[6]);

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
}
checkWork();
addToTest('offer_balance_before', web3.fromWei(eth.getBalance(offer.address)));
addToTest('dao_rewardaccount_before', web3.fromWei(eth.getBalance(dao.DAOrewardAccount())));
console.log("Our proposal is: " + prop_id);

setTimeout(function() {
    miner.stop();
    console.log("After debating period. NOW is: " + Math.floor(Date.now() / 1000));
    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        '$transaction_bytecode', // transaction bytecode
        proposalCreator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );


    console.log("TEST - GIVENPROPID " + offer.givenProposalID());
    console.log("TEST - GIVENHASH: " + offer.givenHash());
    console.log("TEST - GIVENYEA: " + offer.givenYea());
    console.log("TEST - GIVENNAY: " + offer.givenNay());
    console.log("TEST - CALCULATEDHASH: " + offer.calculatedHash());
    console.log("TEST - CALCULATXDATA: " + offer.calculatedTXDATA());

    addToTest('offer_balance_after', web3.fromWei(eth.getBalance(offer.address)));
    addToTest('dao_rewardaccount_after', web3.fromWei(eth.getBalance(dao.DAOrewardAccount())));

    addToTest(
        'offer_diff',
        bigDiff(
            testMap['offer_balance_after'], testMap['offer_balance_before']
        )
    );
    addToTest(
        'rewards_diff',
        bigDiff(
            testMap['dao_rewardaccount_before'], testMap['dao_rewardaccount_after']
        )
    );
    addToTest('got_back_all_money', testMap['rewards_diff'].eq(testMap['offer_diff']));
    addToTest('offer_contract_valid', offer.isContractValid());

    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
miner.start(1);
