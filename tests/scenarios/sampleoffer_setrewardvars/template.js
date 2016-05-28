var dao = web3.eth.contract($dao_abi).at('$dao_address');
var offer = web3.eth.contract($offer_abi).at('$offer_address');
var usn = web3.eth.contract($usn_abi).at('$usn_address');

var dao_rewardaccount_before = eth.getBalance(dao.DAOrewardAccount());
var dao_balance_before = eth.getBalance(dao.address);

// make proposals to set both the rewardDivisor and the deploymentReward
var div_prop_id = attempt_proposal(
    dao, // DAO in question
    '$offer_address', // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Set the reward divisor variable', // description
    '$set_div_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);
var deploy_prop_id = attempt_proposal(
    dao, // DAO in question
    '$offer_address', // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Set the deployment reward proposal', // description
    '$set_deploy_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);


console.log("Voting for both proposals");
for (i = 0; i < eth.accounts.length; i++) {
    dao.vote.sendTransaction(
        div_prop_id,
        true, //omg it's unanimous!
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
    dao.vote.sendTransaction(
        deploy_prop_id,
        true, //omg it's unanimous!
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}
checkWork();

setTimeout(function() {
    miner.stop();
    console.log("After debating period. NOW is: " + Math.floor(Date.now() / 1000));
    attempt_execute_proposal(
        dao, // target DAO
        div_prop_id, // proposal ID
        '$set_div_bytecode', // transaction bytecode
        proposalCreator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );
    attempt_execute_proposal(
        dao, // target DAO
        deploy_prop_id, // proposal ID
        '$set_deploy_bytecode', // transaction bytecode
        proposalCreator, // proposal creator
        true, // should the proposal be closed after this call?
        true // should the proposal pass?
    );

    // test that the variables are set appropriately
    addToTest('offer_reward_divisor', offer.getRewardDivisor());
    addToTest('offer_deployment_reward', offer.getDeploymentReward());

    var actor = eth.accounts[0];
    // emulate a USN node with onetimerward payment smaller than the set deployment reward.
    var dao_rewardaccount_before = eth.getBalance(dao.DAOrewardAccount());
    usn.payOneTimeReward.sendTransaction({from:actor, value: $deployment_reward - 10000, gas: 200000});
    checkWork();
    var dao_rewardaccount_after = eth.getBalance(dao.DAOrewardAccount());
    addToTest('pay_less_fails', dao_rewardaccount_after.eq(dao_rewardaccount_before));

    // emulate a USN node with onetimerward payment bigger than the set deployment reward.
    dao_rewardaccount_before = eth.getBalance(dao.DAOrewardAccount());
    usn.payOneTimeReward.sendTransaction({from:actor, value: $test_deployment_payment, gas: 200000});
    checkWork();
    dao_rewardaccount_after = eth.getBalance(dao.DAOrewardAccount());
    addToTest('reward_payment', dao_rewardaccount_after.sub(dao_rewardaccount_before));

    testResults();
}, $debating_period * 1000);
console.log("Wait for end of debating period");
miner.start(1);
