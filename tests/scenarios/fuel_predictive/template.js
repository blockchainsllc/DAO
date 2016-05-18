var amounts = $amounts;
var dao = web3.eth.contract($dao_abi).at('$dao_address');
console.log("Creating DAO tokens");

if (eth.accounts.length<5) {
    console.log("For this test, at least 5 accounts must be created.");
}
for (i = 0; i < amounts.length; i++) {
    web3.eth.sendTransaction({
        from:eth.accounts[i],
        to: dao.address,
        gas:1000000,
        value:web3.toWei(amounts[i], "ether")
    } /* , function(err, res) {
        if (err) {
            console.log(err);
        }
        console.log("succes: " + res);
    } */);
}

checkWork();

setTimeout(function() {
    miner.stop();
    addToTest('dao_fueled', dao.isFueled());
    addToTest('total_supply', parseFloat(web3.fromWei(dao.totalSupply())));
    var balances = [];
    for (i = 0; i < amounts.length; i++) {
        balances.push(parseFloat(web3.fromWei(dao.balanceOf(eth.accounts[i]))));
    }
    addToTest('balances', balances);

    testResults();
}, $wait_ms);
console.log("Wait for end of creation");
miner.start(1);
