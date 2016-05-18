from utils import constrained_sum_sample_pos, arr_str


scenario_description = (
    "This sccenario fuels the DAO with 5 tokenHollders with 10,20,30,40,50 tokens each"
)


def run(ctx):
    ctx.assert_scenario_ran('deploy')

    creation_secs = ctx.remaining_time()
    ctx.total_supply = 150
    ctx.token_amounts = [10 , 20 , 30, 40, 50]
    ctx.create_js_file(substitutions={
            "dao_abi": ctx.dao_abi,
            "dao_address": ctx.dao_addr,
            "wait_ms": (creation_secs-3)*1000,
            "amounts": arr_str(ctx.token_amounts)
        }
    )
    print(
        "Notice: Fueling period is {} seconds so the test will wait "
        "as much".format(creation_secs)
    )

    ctx.execute(expected={
        "dao_fueled": True,
        "total_supply": 150,
        "balances": [10,20,30,40,50]
    })
