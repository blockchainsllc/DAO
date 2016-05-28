from utils import arr_str, calculate_bytecode
import time

scenario_description = (
    """Test that the offer's client can be properly changed to a split DAO."""
)


def run(ctx):
    ctx.assert_scenario_ran('split')
    # right after the split scenario ran, wait sufficient time for the
    # child_dao closingTime() to be reached.
    time_now = round(time.time())
    if time_now < ctx.child_dao_closing_time:
        wait_for_secs = ctx.child_dao_closing_time - time_now
        print(
            "The child DAO's closing time is not yet reached. Test will wait "
            "for {} seconds.".format(wait_for_secs)
        )
        time.sleep(wait_for_secs)
    transaction_bytecode = calculate_bytecode(
        'updateClientAddress', ('address', ctx.child_dao_address)
    )
    ctx.create_js_file(substitutions={
        "dao_abi": ctx.dao_abi,
        "dao_address": ctx.dao_addr,
        "split_execution_period": ctx.args.split_execution_period,
        "child_dao_curator": ctx.child_dao_curator,
        "child_dao_address": ctx.child_dao_address,
        "offer_abi": ctx.offer_abi,
        "offer_address": ctx.offer_addr,
        "child_dao_members": arr_str(ctx.child_dao_members),
        "proposal_deposit": ctx.args.proposal_deposit,
        "debating_period": ctx.args.proposal_debate_seconds,
        "transaction_bytecode": transaction_bytecode
        }
    )
    print(
        "Notice: Debate period is {} seconds so the test will wait "
        "as much".format(ctx.args.proposal_debate_seconds)
    )

    ctx.execute(expected={
        "offer_client": ctx.child_dao_address,
        "offer_original_client": ctx.dao_addr
    })
