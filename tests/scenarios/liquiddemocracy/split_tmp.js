personal.unlockAccount(eth.accounts[0],'123',3600)
personal.unlockAccount(eth.accounts[1],'123',3600)
personal.unlockAccount(eth.accounts[2],'123',3600)
personal.unlockAccount(eth.accounts[3],'123',3600)
personal.unlockAccount(eth.accounts[4],'123',3600)
personal.unlockAccount(eth.accounts[5],'123',3600)
miner.start()
dao.changeAllowedRecipients.sendTransaction(eth.accounts[1], true, {from: eth.accounts[0], gas: 1000000})
dao.setDelegate(eth.accounts[5], {from: eth.accounts[4], gas: 1000000})

dao.newProposal(eth.accounts[1],0,"split", 0, 40, true, {from: eth.accounts[1], gas: 1000000})

dao.proposals(1)

dao.vote(1, true, {from: eth.accounts[5], gas: 1000000})
dao.getVote(eth.accounts[5],1)

(new Date()).getTime() /1000

dao.splitDAO(1, eth.accounts[1], {from: eth.accounts[4], gas: 4710000})

dao.balanceOf(eth.accounts[4])
