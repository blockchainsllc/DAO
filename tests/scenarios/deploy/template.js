var _curator = web3.eth.accounts[0];
var daoContract = web3.eth.contract($dao_abi);
console.log("Creating DAOCreator Contract");
var creatorContract = web3.eth.contract($creator_abi);
var _daoCreatorContract = creatorContract.new(
    {
	from: web3.eth.accounts[0],
	data: '$creator_bin',
	gas: 4712388
    }, function (e, contract){
	if (e) {
            console.log(e+" at DAOCreator creation!");
	} else if (typeof contract.address != 'undefined') {
        addToTest('dao_creator_address', contract.address);
        checkWork();
        var dao = daoContract.new(
	        _curator,
            _curator,
	        contract.address,
            $default_proposal_deposit,
	        web3.toWei($min_tokens_to_create, "ether"),
	        $closing_time,
            0,
		    {
		        from: web3.eth.accounts[0],
		        data: '$dao_bin',
		        gas: 4712387
		    }, function (e, contract) {
		        // funny thing, without this geth hangs
                if (e) {
                    console.log("Error creating DAO: "+e);
                    return;
                }
		        console.log("At DAO creation callback");
		        if (typeof contract.address != 'undefined') {
                    addToTest('dao_address', contract.address);
		        }
		    });
        checkWork();
	}
    });
checkWork();
var offerContract = web3.eth.contract($offer_abi);
var offer = offerContract.new(
    _curator,
    '0x0',  // This is a hash of the paper contract. Does not matter for testing
    web3.toWei($offer_total, "ether"), //total costs
    web3.toWei($offer_onetime, "ether"), //one time costs
    web3.toWei(1, "ether"), //min daily costs
    web3.toWei(1, "ether"), //reward divison
    web3.toWei(1, "ether"), //deployment rewards
    {
	    from: web3.eth.accounts[0],
	    data: '$offer_bin',
	    gas: 3000000
    }, function (e, contract) {
	    if (e) {
            console.log(e + " at Offer Contract creation!");
	    } else if (typeof contract.address != 'undefined') {
            addToTest('offer_address', contract.address);
        }
    }
);
checkWork();
console.log("mining contract, please wait");
miner.start(1);
setTimeout(function() {
    miner.stop();
    testResults();
}, 3000);


