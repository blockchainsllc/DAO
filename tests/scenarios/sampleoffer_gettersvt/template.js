var offer = web3.eth.contract($offer_abi).at('$offer_address');
var offer_balance_before = eth.getBalance(offer.address);

offer.getTotalCosts.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getOneTimeCosts.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getDailyWithdrawLimit.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getContractor.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getHashOfTheProposalDocument.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getLastPayment.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getDateOfSignature.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getOriginalClient.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getIsContractValid.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getRewardDivisor.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();
offer.getDeploymentReward.sendTransaction({from:eth.accounts[0], value: web3.toWei(10), gas: 200000});
checkWork();

var offer_balance_after = eth.getBalance(offer.address);
addToTest('sample_offer_no_donations', offer_balance_after.eq(offer_balance_before));
testResults();

