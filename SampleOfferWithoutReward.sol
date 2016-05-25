/*
This file is part of the DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
  An Offer from a Contractor to the DAO without any reward going back to
  the DAO.

  Feel free to use as a template for your own proposal.

  Actors:
  - Offerer:    the entity that creates the Offer. Usually it is the initial
                Contractor.
  - Contractor: the entity that has rights to withdraw money to perform
                its project.
  - Client:     the DAO that gives money to the Contractor. It signs off
                the Offer, can adjust daily withdraw limit or even fire the
                Contractor.
*/

import "./DAO.sol";

contract SampleOfferWithoutReward {

    // The total cost of the Offer. Exactly this amount is transfered from the
    // Client to the Offer contract when the Offer is signed by the Client.
    // Set once by the Offerer.
    uint public totalCosts;

    // Initial withdraw to the Contractor. It is done the moment the Offer is
    // signed.
    // Set once by the Offerer.
    uint public oneTimeCosts;

    // The minimal daily withdraw limit that the Contractor accepts.
    // Set once by the Offerer.
    uint public minDailyWithdrawLimit;

    // The amount of money the Contractor has right to withdraw daily above the
    // initial withdraw. The Contractor does not have to do the withdraws every
    // day as this amount accumulates.
    uint public dailyWithdrawLimit;

    // The address of the Contractor.
    address public contractor;

    // The address of the Proposal/Offer document.
    bytes32 public IPFSHashOfTheProposalDocument;


    uint public paidOut;

    uint public dateOfSignature;
    DAO public client; // address of DAO
    DAO public originalClient; // address of DAO who signed the contract
    bool public isContractValid;

    modifier onlyClient {
        if (msg.sender != address(client))
            throw;
        _
    }

    // Prevents methods from perfoming any value transfer
    modifier noEther() {if (msg.value > 0) throw; _}

    function SampleOfferWithoutReward(
        address _contractor,
        address _client,
        bytes32 _IPFSHashOfTheProposalDocument,
        uint _totalCosts,
        uint _oneTimeCosts,
        uint _minDailyWithdrawLimit
    ) {
        contractor = _contractor;
        originalClient = DAO(_client);
        client = DAO(_client);
        IPFSHashOfTheProposalDocument = _IPFSHashOfTheProposalDocument;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyWithdrawLimit = _minDailyWithdrawLimit;
        dailyWithdrawLimit = _minDailyWithdrawLimit;
    }

    function sign() {
        if (msg.sender != address(originalClient) // no good samaritans give us money
            || msg.value != totalCosts    // no under/over payment
            || dateOfSignature != 0)      // don't sign twice
            throw;
        if (!contractor.send(oneTimeCosts))
            throw;
        dateOfSignature = now;
        isContractValid = true;
    }

    function setDailyWithdrawLimit(uint _dailyWithdrawLimit) onlyClient noEther {
        if (_dailyWithdrawLimit >= minDailyWithdrawLimit)
            dailyWithdrawLimit = _dailyWithdrawLimit;
    }

    // "fire the contractor"
    function returnRemainingEther() onlyClient {
        if (originalClient.DAOrewardAccount().call.value(this.balance)())
            isContractValid = false;
    }

    function getDailyPayment() {
        if (msg.sender != contractor)
            throw;
        uint totalWithdrawal = (now - dateOfSignature + 1 days) / (1 days) * dailyWithdrawLimit;
        if (paidOut > totalWithdrawal)
            throw;

        uint amount = totalWithdrawal - paidOut;
        if (amount > this.balance) {
            amount = this.balance;
        }
        if (contractor.send(amount))
            paidOut += amount;
    }

    // Change the client DAO by giving the new DAO's address
    // warning: The new DAO must come either from a split of the original
    // DAO or an update via `newContract()` so that it can claim rewards
    function updateClientAddress(DAO _newClient) onlyClient noEther {
        client = _newClient;
    }

    function () {
        throw; // this is a business contract, no donations
    }
}
