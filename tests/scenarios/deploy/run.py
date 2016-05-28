import sys
import json
from utils import extract_test_dict, seconds_in_future


scenario_description = (
    "Deploying of the DAO, DAOcreator and SampleOffer contracts in the "
    "blockchain and noting down of their addresses"
)


def calculate_closing_time(obj, script_name, substitutions):
    obj.closing_time = seconds_in_future(obj.args.deploy_creation_seconds)
    substitutions['closing_time'] = obj.closing_time
    return substitutions


def run(ctx):
    ctx.create_js_file(
        substitutions={
            "dao_abi": ctx.dao_abi,
            "dao_bin": ctx.dao_bin,
            "creator_abi": ctx.creator_abi,
            "creator_bin": ctx.creator_bin,
            "offer_abi": ctx.offer_abi,
            "offer_bin": ctx.offer_bin,
            "usn_abi": ctx.usn_abi,
            "usn_bin": ctx.usn_bin,
            "offer_onetime": ctx.args.deploy_onetime_costs,
            "offer_total": ctx.args.deploy_total_costs,
            "min_tokens_to_create": ctx.args.deploy_min_tokens_to_create,
            "default_proposal_deposit": ctx.args.deploy_proposal_deposit
        },
        cb_before_creation=calculate_closing_time
    )
    output = ctx.run_script('deploy.js')
    results = extract_test_dict('deploy', output)

    try:
        ctx.dao_creator_addr = results['dao_creator_address']
        ctx.dao_addr = results['dao_address']
        ctx.offer_addr = results['offer_address']
        ctx.usn_addr = results['usn_address']
    except:
        print(
            "ERROR: Could not find expected results in the deploy scenario"
            ". The output was:\n{}".format(output)
        )
        sys.exit(1)
    print("DAO Creator address is: {}".format(ctx.dao_creator_addr))
    print("DAO address is: {}".format(ctx.dao_addr))
    print("SampleOffer address is: {}".format(ctx.offer_addr))
    print("USNRewardPayOut address is: {}".format(ctx.usn_addr))
    with open(ctx.save_file, "w") as f:
        f.write(json.dumps({
            "dao_creator_addr": ctx.dao_creator_addr,
            "dao_addr": ctx.dao_addr,
            "offer_addr": ctx.offer_addr,
            "usn_addr": ctx.usn_addr,
            "closing_time": ctx.closing_time
        }))

    # after deployment recalculate for the subsequent tests what the min
    # amount of tokens is in the case of extrabalance tests
    if ctx.scenario_uses_extrabalance():
        ctx.args.deploy_min_tokens_to_create = (
            int(ctx.args.deploy_min_tokens_to_create * 1.5)
        )
