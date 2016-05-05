var amounts = $amounts;

var dao = web3.eth.contract($dao_abi).at('$dao_address');
console.log("Creating DAO tokens");
for (i = 0; i < eth.accounts.length; i++) {
    web3.eth.sendTransaction({
        from:eth.accounts[i],
        to: dao.address,
        gas:1000000,
        value:web3.toWei(amounts[i], "ether")
    });
}

checkWork();

setTimeout(function() {
    miner.stop();
    addToTest('dao_min_tokens_to_create', dao.minTokensToCreate());
    addToTest('dao_fueled', dao.isFueled());
    addToTest('total_supply', parseFloat(web3.fromWei(dao.totalSupply())));

    // since fueling failed let's get a refund
    var eth_balance_before_refund = [];
    for (i = 0; i < eth.accounts.length; i++) {
        eth_balance_before_refund.push(web3.fromWei(eth.getBalance(eth.accounts[i])));
    }
    addToTest('eth_balance_before_refund', eth_balance_before_refund);

    for (i = 0; i < eth.accounts.length; i++) {
        dao.refund.sendTransaction({
            from:eth.accounts[i],
            gas:1000000
        });
    }
    checkWork();
    // try to ask for a refund again and see if we get more (we shouldn't)
    for (i = 0; i < eth.accounts.length; i++) {
        dao.refund.sendTransaction({
            from:eth.accounts[i],
            gas:1000000
        });
    }
    checkWork();
    var eth_balance_after_refund = [];
    for (i = 0; i < eth.accounts.length; i++) {
        eth_balance_after_refund.push(web3.fromWei(eth.getBalance(eth.accounts[i])));
    }
    addToTest('eth_balance_after_refund', eth_balance_after_refund);

    var refund = [];
    for (i = 0; i < eth.accounts.length; i++) {
        refund.push((bigDiffRound(
            testMap['eth_balance_after_refund'][i],
            testMap['eth_balance_before_refund'][i]
        )));
    }
    addToTest('refund', refund);

    testResults();
}, $wait_ms);
console.log("Wait for end of creation");
miner.start(1);
