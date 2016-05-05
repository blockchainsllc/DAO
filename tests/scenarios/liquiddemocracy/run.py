import random
from utils import arr_str, create_votes_array

scenario_description = (
    "This scenario alternates varios createProposal, vote, transfer,"
    " setDelegate in various tokenHolders/delegates."
    " It checks that all the votes are countent in the correct way after each"
    " action"
)




def run(ctx):
    ctx.assert_scenario_ran('fuel_predictive')

    minamount = 2  # is determined by the total costs + one time costs
    amount = random.randint(minamount, sum(ctx.token_amounts))
    ctx.create_js_file(substitutions={
        "dao_abi": ctx.dao_abi,
        "dao_address": ctx.dao_addr,
        "offer_abi": ctx.offer_abi,
        "offer_address": ctx.offer_addr,
        "offer_amount": amount,
        "offer_desc": 'Test Proposal',
        "proposal_deposit": ctx.args.proposal_deposit,
        "transaction_bytecode": '0x2ca15122',  # solc --hashes SampleOffer.sol
        "debating_period": ctx.args.proposal_debate_seconds,
    })

    ctx.execute(expected={
        "y2": 150,
        "n2": 0,
        "y3": 130,
        "n3": 20,
        "y4": 130,
        "n4": 20,
        "y5": 90,
        "n5": 60,
        "y6": 40,
        "n6": 110,
        "y7": 40,
        "n7": 110,
        "y8": 40,
        "n8": 110,
        "s10_delegated_votes_def_before": 150,
        "s10_delegated_votes_def_after": 80,
        "s10_delegated_votes_0_before": 0,
        "s10_delegated_votes_0_after": 0,
        "s10_delegated_votes_5_before": 0,
        "s10_delegated_votes_5_after": 70,
        "y12": 70,
        "n12": 0,
        "y13": 40,
        "n13": 30,
        "y14": 0,
        "n14": 70,
        "y15": 80,
        "n15": 70,
        "y16": 30,
        "n16": 120,

        "s18_tokenholder_votes_3_before": 40,
        "s18_tokenholder_votes_3_after": 35,
        "s18_tokenholder_votes_5_before": 0,
        "s18_tokenholder_votes_5_after": 5,
        "s18_delegated_votes_def_before": 80,
        "s18_delegated_votes_def_after": 85,
        "s18_delegated_votes_5_before": 70,
        "s18_delegated_votes_5_after": 65,
        "y19": 20,
        "n19": 0,

        "s20_tokenholder_votes_1_before": 20,
        "s20_tokenholder_votes_1_after": 13,
        "s20_tokenholder_votes_5_before": 0,
        "s20_tokenholder_votes_5_after": 12,
        "s20_delegated_votes_def_before": 80,
        "s20_delegated_votes_def_after": 85,
        "s20_delegated_votes_5_before": 70,
        "s20_delegated_votes_5_after": 65,


        "y21": 60,
        "n21": 0,
        "y22": 60,
        "n22": 30,
        "y25": 110,
        "n25": 30,

        "y26": 127,
        "n26": 0,

        "y27": 127,
        "n27": 23,

        "y30": 140,
        "n30": 10,

        "y32": 35,
        "n32": 0,

        "y33": 35,
        "n33": 0,

        "y34": 150,
        "n34": 0,

        "s36_tokenholder_votes_1_before": 13,
        "s36_tokenholder_votes_1_after": 0,
        "s36_delegated_votes_def_before": 35,
        "s36_delegated_votes_def_after": 22,
        "s36_delegated_votes_1_before": 0,
        "s36_delegated_votes_1_after": 0,

        "s37_tokenholder_votes_0_before": 10,
        "s37_tokenholder_votes_0_after": 0,
        "s37_delegated_votes_def_before": 35,
        "s37_delegated_votes_def_after": 12,
        "s37_delegated_votes_0_before": 0,
        "s37_delegated_votes_0_after": 0,

        "s38_tokenholder_votes_4_before": 50,
        "s38_tokenholder_votes_4_after": 0,
        "s38_delegated_votes_def_before": 35,
        "s38_delegated_votes_def_after": 12,
        "s38_delegated_votes_5_before": 115,
        "s38_delegated_votes_5_after": 65

    })
