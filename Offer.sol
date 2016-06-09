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
  An Offer from a Contractor to the DAO. No logic about the DAO reward is
  included in this contract.

  Feel free to use as a base contract for your own proposal.

  Actors:
  - Offerer:    the entity that creates the Offer. Usually it is the initial
                Contractor.
  - Contractor: the entity that has rights to withdraw ether to perform
                its project.
  - Client:     the DAO that gives ether to the Contractor. It accepts
                the Offer, can adjust daily withdraw limit or even fire the
                Contractor.
*/

import "./DAO.sol";

contract Offer {

    // The total cost of the Offer for the Client. Exactly this amount is
    // transfered from the Client to the Offer contract when the Offer is
    // accepted by the Client. Set once by the Offerer.
    uint totalCost;

    // Initial withdraw to the Contractor. It is done the moment the Offer is
    // accepted. Set once by the Offerer.
    uint initialWithdraw;

    // The minimal daily withdraw limit that the Contractor accepts.
    // Set once by the Offerer.
    uint128 minDailyWithdrawLimit;

    // The amount of wei the Contractor has right to withdraw daily above the
    // initial withdraw. The Contractor does not have to do the withdraws every
    // day as this amount accumulates.
    uint128 dailyWithdrawLimit;

    // The address of the Contractor.
    address contractor;

    // The hash of the Proposal/Offer document.
    bytes32 hashOfTheProposalDocument;

    // The time of the last withdraw to the Contractor.
    uint lastWithdraw;

    uint dateOfAcceptance;
    DAO client;          // The address of the current Client.
    DAO originalClient;  // The address of the Client who accepted the Offer.

    modifier onlyClient {
        if (msg.sender != address(client))
            throw;
        _
    }

    // Prevents methods from perfoming any value transfer
    modifier noEther() {if (msg.value > 0) throw; _}

    function Offer(
        address _contractor,
        address _client,
        bytes32 _hashOfTheProposalDocument,
        uint _totalCost,
        uint _initialWithdraw,
        uint128 _minDailyWithdrawLimit
    ) {
        contractor = _contractor;
        originalClient = DAO(_client);
        client = DAO(_client);
        hashOfTheProposalDocument = _hashOfTheProposalDocument;
        totalCost = _totalCost;
        initialWithdraw = _initialWithdraw;
        minDailyWithdrawLimit = _minDailyWithdrawLimit;
        dailyWithdrawLimit = _minDailyWithdrawLimit;
    }

    // non-value-transfer getters
    function getTotalCost() noEther constant returns (uint) {
        return totalCost;
    }

    function getInitialWithdraw() noEther constant returns (uint) {
        return initialWithdraw;
    }

    function getMinDailyWithdrawLimit() noEther constant returns (uint128) {
        return minDailyWithdrawLimit;
    }

    function getDailyWithdrawLimit() noEther constant returns (uint128) {
        return dailyWithdrawLimit;
    }

    function getContractor() noEther constant returns (address) {
        return contractor;
    }

    function getHashOfTheProposalDocument() noEther constant returns (bytes32) {
        return hashOfTheProposalDocument;
    }

    function getLastWithdraw() noEther constant returns (uint) {
        return lastWithdraw;
    }

    function getDateOfAcceptance() noEther constant returns (uint) {
        return dateOfAcceptance;
    }

    function getClient() noEther constant returns (DAO) {
        return client;
    }

    function getOriginalClient() noEther constant returns (DAO) {
        return originalClient;
    }

    function getIsContractValid() noEther constant returns (bool) {
        return this.balance > 0;
    }

    function accept() {
        if (msg.sender != address(originalClient) // no good samaritans give us ether
            || msg.value != totalCost    // no under/over payment
            || dateOfAcceptance != 0)    // don't accpet twice
            throw;
        if (!contractor.send(initialWithdraw))
            throw;
        dateOfAcceptance = now;
        lastWithdraw = now;
    }

    function setDailyWithdrawLimit(uint128 _dailyWithdrawLimit) onlyClient noEther {
        if (_dailyWithdrawLimit >= minDailyWithdrawLimit)
            dailyWithdrawLimit = _dailyWithdrawLimit;
    }

    // Terminate the ongoing Offer.
    //
    // The Client can terminate the ongoing Offer using this method. Using it
    // on an invalid (balance 0) Offer has no effect. The Contractor looses
    // right to any ethers left in the Offer.
    function terminate() noEther onlyClient {
        originalClient.DAOrewardAccount().call.value(this.balance)();
    }

    // Withdraw to the Contractor.
    //
    // Withdraw the amount of ether the Contractor has right to according to
    // the current withdraw limit.
    // Executing this function before the Offer is accepted by the Client
    // makes no sense as this contract has no ether.
    function withdraw() noEther {
        if (msg.sender != contractor)
            throw;
        uint timeSincelastWithdraw = now - lastWithdraw;
        // Calculate the amount using 1 second precision.
        uint amount = (timeSincelastWithdraw * dailyWithdrawLimit) / (1 days);
        if (amount > this.balance) {
            amount = this.balance;
        }
        if (contractor.send(amount))
            lastWithdraw = now;
    }

    // Change the client DAO by giving the new DAO's address
    // warning: The new DAO must come either from a split of the original
    // DAO or an update via `newContract()` so that it can claim rewards
    function updateClientAddress(DAO _newClient) onlyClient noEther {
        client = _newClient;
    }

    function () {
        throw; // This is a business contract, no donations.
    }
}
