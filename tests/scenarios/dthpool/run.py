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
        "dthpool_abi": ctx.dthpool_abi,
        "dthpool_address": ctx.dthpool_addr,
        "proposal_deposit": ctx.args.proposal_deposit,
        "transaction_bytecode": '0x2ca15122'  # solc --hashes SampleOffer.sol
    })

    ctx.execute(expected={
        "notDelegated": 8,
        "delegated": 2,
        "voteSet1": True,
        "willVote1": True,
        "supportsProposal1": True,
        "executed1": False,
        "y6": 2,
        "n6": 0
    })
