// first run prepare.js to import the compiled source code and some other helper variables
// before you do that run prepare.py to compile the latest version of the software in DAO
// and populate the helper variables

personal.unlockAccount(eth.accounts[0]);
var daoContract = web3.eth.contract(dao_abi);
var min_tokens_to_create = 1;
var closing_time = Math.floor(Date.now() / 1000) + seconds_from_now;

var creatorContract = web3.eth.contract(creator_abi);
console.log("Creating DAOCreator Contract");
var _daoCreatorContract = creatorContract.new(
    {
	    from: web3.eth.accounts[0],
	    data: creator_bin,
	    gas: 4700000
    }, function (e, contract){
	    if (e) {
            console.log(e+ " at DAOCreator creation!");
	    } else if (typeof contract.address != 'undefined') {
            console.log("Creating the actual DAO");
            var dao = daoContract.new(
	            curator,
                curator,
	            contract.address,
                web3.toWei(default_proposal_deposit, "ether"),
	            web3.toWei(min_tokens_to_create, "ether"),
                closing_time,
                0,
		        {
		            from: web3.eth.accounts[0],
		            data: dao_bin,
		            gas: 4700000
		        }, function (e, our_contract) {
		            // funny thing, without this geth hangs
		            console.log("At DAO creation callback");
		            if (typeof our_contract.address != 'undefined') {
                        console.log("our new DAO address is: " + our_contract.address);
		            }
		        });

	    }
    });
