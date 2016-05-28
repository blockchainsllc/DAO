from utils import arr_str, calculate_bytecode
import time

scenario_description = (
    """Test that the offer's contract can't receive any money through its
 getter functions."""
)


def run(ctx):
    ctx.assert_scenario_ran('proposal')
    ctx.create_js_file(substitutions={
        "offer_abi": ctx.offer_abi,
        "offer_address": ctx.offer_addr,
    })

    ctx.execute(expected={
        "sample_offer_no_donations": True,
    })
