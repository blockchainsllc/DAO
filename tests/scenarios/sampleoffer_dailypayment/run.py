from utils import calculate_bytecode, to_wei

scenario_description = (
    "Test a normal usage of the SampleOffer contract where there is a payment "
    "coming in from a deployed USN node and it goes to the DAO Reward account."
    "Also test that the contractor can properly withdraw the daily payment, "
    "calculating how much Wei he entitlted to depend in the 'day-periods' "
    "that have passed since signing the contract."
)


def run(ctx):
    ctx.assert_scenario_ran('proposal')
    daily_limit_in_ether = 5
    pay_reward_amount = 10
    bytecode = calculate_bytecode('setDailyWithdrawLimit', ('uint128', to_wei(daily_limit_in_ether)))
    ctx.create_js_file(substitutions={
        "dao_abi": ctx.dao_abi,
        "dao_address": ctx.dao_addr,
        "offer_abi": ctx.offer_abi,
        "offer_address": ctx.offer_addr,
        "usn_abi": ctx.usn_abi,
        "usn_address": ctx.usn_addr,
        "proposal_deposit": ctx.args.proposal_deposit,
        "pay_reward_amount": pay_reward_amount,
        "transaction_bytecode": bytecode,
        "debating_period": ctx.args.proposal_debate_seconds,
        "offer_payment_period": ctx.args.deploy_offer_payment_period
    })
    print(
        "Notice: Debate period is {} seconds so the test will wait "
        "as much".format(ctx.args.proposal_debate_seconds)
    )

    ctx.execute(expected={
        "offer_daily_withdraw_limit": daily_limit_in_ether,
        "contractor_paid_expected": True,
        "dao_rewardaccount_diff": pay_reward_amount,
        "sample_offer_no_donations": True,
    })
