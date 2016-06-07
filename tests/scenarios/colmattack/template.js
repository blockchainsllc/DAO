var dao = web3.eth.contract($dao_abi).at('$dao_address');

var attacker = eth.accounts[2];
addToTest('attacker_balance_before', web3.fromWei(eth.getBalance(attacker)));
addToTest('attacker_dao_balance_before', web3.fromWei(dao.balanceOf(attacker)));

// add curator to the whitelist
dao.changeAllowedRecipients.sendTransaction(curator, true, {from:curator, gas:200000});

var attack_proposal_id = attempt_proposal(
    dao, // DAO in question
    curator, // recipient
    attacker, // proposal creator
    0, // proposal amount in ether
    'The colm attack proposal with a big deposit', // description
    '', //bytecode
    $attack_debating_period, // debating period
    $attack_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);

var split_proposal_id = attempt_proposal(
    dao, // DAO in question
    attacker, // recipient
    attacker, // proposal creator
    0, // proposal amount in ether
    'attacker wants to split out', // description
    '', //bytecode
    $split_debating_period, // debating period
    0, // proposal deposit in ether
    true // whether it's a split proposal or not
);

console.log("Vote on proposals");
// everyone votes on the attack proposal
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        attack_proposal_id,
        true,
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}
// our attacker also votes on his split
dao.vote.sendTransaction(split_proposal_id, true, {from: attacker, gas: 1000000});
checkWork();


setTimeout(function() {
    miner.stop();
    console.log("Attack debate period over.");

    setTimeout(function() {
        miner.stop();

        console.log("Split debate period over. Executing the split proposal...");
        // now the attacker splits
        dao.splitDAO.sendTransaction(
            split_proposal_id,
            attacker,
            {from:attacker, gas: 4700000}
        );
        checkWork();

        console.log("Right after the split, execute the attack proposal to get the deposit back");
        attempt_execute_proposal(
            dao, // target DAO
            attack_prop_id, // proposal ID
            attacker, // proposal creator
            true, // should the proposal be closed after this call?
            true // should the proposal pass?
        );

        addToTest('split_proposal_id', split_proposal_id);
        addToTest('split_proposal_passed', dao.proposals(split_proposal_id)[5]);
        addToTest('split_dao', dao.splitProposalNewAddress(split_proposal_id, 0));
        var splitdao = web3.eth.contract($dao_abi).at(testMap['split_dao']);
        addToTest('split_dao_total_supply', web3.fromWei(eth.getBalance(splitdao.address)));
        addToTest('attacker_balance_after', web3.fromWei(eth.getBalance(attacker)));

        // now comes the check. His balance should be the same but so should be the amount
        // balance of the split DAO and the balance he owned in the previous DAO. With the
        // colm attack that would not be the case as he would also get part of his proposal
        // deposit into the new DAO and thus make profit.
        addToTest(
            'attacker_eth_balance_diff',
            bigDiffRound(testMap['attacker_balance_after'], testMap['attacker_balance_before'])
        );
        addToTest(
            'attacker_dao_balance_diff',
            bigDiffRound(testMap['split_dao_total_supply'], testMap['attacker_dao_balance_before'])
        );
        testResults();
    }, ($split_debating_period - $attack_debating_period) * 1000);

    miner.start(1);
    console.log("Waiting until the split proposal debate is over");
}, $attack_debating_period * 1000);
miner.start(1);
console.log("Waiting for the split debate period.");
