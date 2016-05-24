from utils import calculate_bytecode

scenario_description = (
    "Test that the contractor can be fired once the contract has been signed"
    " and that all the remaining money is returned to the DAO."
)


def run(ctx):
    ctx.assert_scenario_ran('proposal')
    bytecode = calculate_bytecode('returnRemainingEther', ("uint256", 2))
    ctx.create_js_file(substitutions={
        "dao_abi": ctx.dao_abi,
        "dao_address": ctx.dao_addr,
        "offer_abi": ctx.offer_abi,
        "offer_address": ctx.offer_addr,
        "proposal_deposit": ctx.args.proposal_deposit,
        "transaction_bytecode": bytecode,
        "debating_period": ctx.args.proposal_debate_seconds,
    })
    print(
        "Notice: Debate period is {} seconds so the test will wait "
        "as much".format(ctx.args.proposal_debate_seconds)
    )

    ctx.execute(expected={
        "got_back_all_money": True,
        "offer_contract_valid": False
    })
