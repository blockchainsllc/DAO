# The DAO


## What is it?
A generic DAO (Decentralized Autonomous Organization) framework written in Solidity to run on the Ethereum block chain. 

Feel free to reuse to create your own Decentralized Autonomous Organization.

**Reference:** *"Decentralized autonomous organization to automate governance" -* [White Paper](https://download.slock.it/public/DAO/WhitePaper.pdf) - [Primer](https://blog.slock.it/a-primer-to-the-decentralized-autonomous-organization-dao-69fb125bd3cd)



## Disclaimer

The future remains a work in progress. Our vision exists in a world where laws vary widely. It is important to remember that anyone who uses DAO code will do so at their own risk. We can’t speculate about the legal status of DAOs worldwide. Whatever our personal beliefs may be, people must draw their own conclusions, relying on legal advice where appropriate. The Authors are not law firm and we are not in the business of offering legal advice. 

**If you create a DAO it will be your DAO, and you will be responsible for its operation.**



## Contact
A very active community can be found on  [slack](http://slack.slock.it:3000)






## Overview

Our generic DAO code allows people to create self-governing, decentralized autonomous organizations governed by software code with instructions written immutably to the blockchain.

We are making the generic DAO model we developed free and open source, so it can be reused by anyone wishing to put together a transparent organization where governance and decision making systems are immutably programmed in the Blockchain. This code been reviewed by hundreds of pairs of eyes from our community and by one of the most respected auditing companies in the world, Deja Vu.

This DAO model is open source under the LGPL, so it can be reused by anyone wishing to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain.

Note: Although the word "contract" is used in the DAO code, the term is a programming convention and is not being used as a legal term of art.  The DAO does not practice law and the authors of this code do not practice law are not your lawyers.  The term is a programming convention, not a representation that the code is in and of itself a legally binding and enforceable contract. If you have questions about legal enforceability, consult with legal counsel.






## Solidity files

### DAO.sol:
Generic smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making.

### Token.sol: 
Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and its corresponding approval process.

### TokenSale.sol: 
Token Sale contract, used by the DAO to sell its tokens and initialize its ether.

### SampleOffer.sol
Sample Proposal from a Contractor to the DAO. Feel free to use as a template for your own proposal.

### ManagedAccount.sol
Basic account, used by the DAO contract to separately manage both the rewards and the extraBalance accounts. 

### DAOTokenSaleProxyTransferer.sol
This contract is used as a fall back in case an exchange doesn't implement the "add data to a transaction" feature in a timely manner, preventing it from calling buyTokenProxy().







## Licensing
The DAO is free software: you can redistribute it and/or modify it under the terms of the GNU lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU lesser General Public License for more details.

A copy of the GNU lesser General Public License is included
along with the DAO. See LICENSE.






## Additional Disclaimers

NEITHER THE SOFTWARE NOR ITS CREATORS PROVIDE LEGAL ADVICE AND THIS CODE WAS NOT CREATED TO PROVIDE LEGAL ADVICE OR AS A SUBSTITUTE FOR LEGAL ADVICE. BY USING THIS CODE YOU ALSO AGREE:

a. The creators of the Software and its contributors are not your lawyers.

b. The Software is not a lawyer.

c. Your use of the Software does not, in and of itself, create a legally binding contract in any jurisdiction and does not establish a lawyer-client relationship. Your communication with a non-lawyer will not be subject to the attorney-client privilege and (depending on your jurisdiction) may not be entitled to protection as confidential communication.

d. The dissemination, distribution, or usage of this software shall not constitute the provision of legal advice within your jurisdiction. Unless you are legally authorized and licensed to do so, you will not use the Software to provide or assist in the provision of legal advice.

e. You acknowledge and understand that each jurisdiction has its own particular rules regarding the practice of law. IF YOU USE THIS SOFTWARE TO PROVIDE LEGAL ADVICE YOU MAY BE SUBJECT TO CIVIL AND CRIMINAL LIABILITY. PRACTICING LAW WITHOUT A LICENSE IS A VIOLATION OF CRIMINAL LAW IN SOME JURISDICTIONS. CONSULT A LAWYER LICENSED IN YOUR JURISDICTION IF YOU HAVE ANY QUESTIONS ABOUT WHAT DOES OR DOES NOT CONSTITUTE THE PRACTICE OF LAW.

f. The providers of this software neither warrant nor guarantee this software shall meet the requirements of any particular legal system to form a legally binding contract, nor it it their intention to directly or indirectly facilitate or encourage the unauthorized practice of law.

g. You agree that in order for you to form a legally binding contract that you shall seek legal advice from an appropriately qualified and experienced lawyer within your jurisdiction.

h.  Issuance of DAO tokens may constitute the sale of securities in certain jurisdictions. Seek appropriate legal advice before deploying DAO code.



