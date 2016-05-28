var _curator = web3.eth.accounts[0];
var daoContract = web3.eth.contract($dao_abi);
console.log("Creating DAOCreator Contract");
var creatorContract = web3.eth.contract($creator_abi);
var _daoCreatorContract = creatorContract.new(
    {
	from: web3.eth.accounts[0],
	data: '$creator_bin',
	gas: 4700000
    }, function (e, contract){
	if (e) {
            console.log(e+" at DAOCreator creation!");
	} else if (typeof contract.address != 'undefined') {
        addToTest('dao_creator_address', contract.address);
        checkWork();
        var dao = daoContract.new(
	        _curator,
	        contract.address,
            $default_proposal_deposit,
	        web3.toWei($min_tokens_to_create, "ether"),
	        $closing_time,
            0,
		    {
		        from: web3.eth.accounts[0],
		        data: '$dao_bin',
		        gas: 4700000
		    }, function (e, contract) {
		        // funny thing, without this geth hangs
		        console.log("At DAO creation callback");
		        if (typeof contract.address != 'undefined') {
                    addToTest('dao_address', contract.address);

                    // now deploy the Sample Offer
                    var offerContract = web3.eth.contract($offer_abi);
                    var offer = offerContract.new(
                        contractor,
                        contract.address, // client DAO address
                        '0x0',  // This is a hash of the paper contract. Does not matter for testing
                        web3.toWei($offer_total, "ether"), //total costs
                        web3.toWei($offer_onetime, "ether"), //one time costs
                        web3.toWei(1, "ether"), //min daily costs
                        {
	                        from: contractor,
	                        data: '$offer_bin',
	                        gas: 3000000
                        }, function (e, offer_contract) {
	                        if (e) {
                                console.log(e + " at Offer Contract creation!");
	                        } else if (typeof offer_contract.address != 'undefined') {
                                addToTest('offer_address', offer_contract.address);

                                // finally now deploy the USNRewardPAyout contract
                                var usnContract = web3.eth.contract($usn_abi);
                                var usn = usnContract.new(
                                    offer_contract.address,
                                    {
                                        from: contractor,
                                        data: '$usn_bin',
	                                    gas: 3000000
                                    }, function (e, usn_contract) {
	                                    if (e) {
                                            console.log(e + " at USNRewardpayout Contract creation!");
	                                    } else if (typeof usn_contract.address != 'undefined') {
                                            addToTest('usn_address', usn_contract.address);
                                            testResults();
                                        }
                                    }
                                );
                                checkWork();
                            }
                        });
                    checkWork();
		        }
		    });
        checkWork();
	}
    });
checkWork();

