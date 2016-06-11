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

    // Initial withdrawal to the Contractor. It is done the moment the
    // Offer is accepted. Set once by the Offerer.
    uint initialWithdrawal;

    // The minimum daily withdrawal limit that the Contractor accepts.
    // Set once by the Offerer.
    uint128 minDailyWithdrawalLimit;

    // The amount of wei the Contractor has right to withdraw daily above the
    // initial withdrawal. The Contractor does not have to perform the
    // withdrawals every day as this amount accumulates.
    uint128 dailyWithdrawalLimit;

    // Period of time after which money can be withdrawn from this contract
    uint payoutFreezePeriod;

    // The address of the Contractor.
    address contractor;

    // The hash of the Proposal/Offer document.
    bytes32 hashOfTheProposalDocument;

    // The time of the last withdrawal to the Contractor.
    uint lastWithdrawal;

    // The timestamp when the offer contract was accepted.
    uint dateOfSignature;
    // The address of the current Client.
    DAO client;
    // The address of the Client who accepted the Offer.
    DAO originalClient;
    bool isContractValid;
    bool initialWithdrawalDone;

    // Voting deadline of the proposal
    uint votingDeadline;

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
        uint _initialWithdrawal,
        uint128 _minDailyWithdrawalLimit,
        uint _payoutFreezePeriod
    ) {
        contractor = _contractor;
        originalClient = DAO(_client);
        client = DAO(_client);
        hashOfTheProposalDocument = _hashOfTheProposalDocument;
        totalCost = _totalCost;
        initialWithdrawal = _initialWithdrawal;
        minDailyWithdrawalLimit = _minDailyWithdrawalLimit;
        dailyWithdrawalLimit = _minDailyWithdrawalLimit;
        payoutFreezePeriod = _payoutFreezePeriod;
    }

    // non-value-transfer getters
    function getTotalCost() noEther constant returns (uint) {
        return totalCost;
    }

    function getInitialWithdrawal() noEther constant returns (uint) {
        return initialWithdrawal;
    }

    function getMinDailyWithdrawalLimit() noEther constant returns (uint128) {
        return minDailyWithdrawalLimit;
    }

    function getDailyWithdrawalLimit() noEther constant returns (uint128) {
        return dailyWithdrawalLimit;
    }

    function getPayoutFreezePeriod() noEther constant returns (uint) {
        return payoutFreezePeriod;
    }

    function getContractor() noEther constant returns (address) {
        return contractor;
    }

    function getHashOfTheProposalDocument() noEther constant returns (bytes32) {
        return hashOfTheProposalDocument;
    }

    function getLastWithdrawal() noEther constant returns (uint) {
        return lastWithdrawal;
    }

    function getDateOfSignature() noEther constant returns (uint) {
        return dateOfSignature;
    }

    function getClient() noEther constant returns (DAO) {
        return client;
    }

    function getOriginalClient() noEther constant returns (DAO) {
        return originalClient;
    }

    function getIsContractValid() noEther constant returns (bool) {
        return isContractValid;
    }

    function getInitialWithdrawalDone() noEther constant returns (bool) {
        return initialWithdrawalDone;
    }

    function sign() {
        if (msg.sender != address(originalClient) // no good samaritans give us ether
            || msg.value != totalCost    // no under/over payment
            || dateOfSignature != 0      // don't accept twice
            || votingDeadline == 0       // votingDeadline needs to be set
            || now < votingDeadline + 8 days)
            throw;

        lastWithdrawal = now + payoutFreezePeriod;
        if (payoutFreezePeriod == 0) {
            if (!contractor.send(initialWithdrawal))
                throw;
            initialWithdrawalDone = true;
        }
        dateOfSignature = now;
        isContractValid = true;
    }

    // Once a proposal is submitted, the Contractor should call this
    // function to get the voting deadline of the proposal
    function getVotingDeadline(uint _proposalID) noEther {
        if (msg.sender != contractor) throw;
        var (recipient,,,_votingDeadline,open,) = client.proposals(_proposalID);
        if (recipient == address(this)
            && _votingDeadline > now
            && open
            && _votingDeadline == 0) {
            votingDeadline = _votingDeadline;
        }
    }

    function setDailyWithdrawLimit(uint128 _dailyWithdrawalLimit) onlyClient noEther {
        if (_dailyWithdrawalLimit >= minDailyWithdrawalLimit)
            dailyWithdrawalLimit = _dailyWithdrawalLimit;
    }

    // Terminate the ongoing Offer.
    //
    // The Client can terminate the ongoing Offer using this method. Using it
    // on an invalid (balance 0) Offer has no effect. The Contractor loses
    // right to any ether left in the Offer.
    function terminate() noEther onlyClient {
        if (originalClient.DAOrewardAccount().call.value(this.balance)())
            isContractValid = false;
    }

    // Withdraw to the Contractor.
    //
    // Withdraw the amount of ether the Contractor has right to according to
    // the current withdraw limit.
    // Executing this function before the Offer is accepted by the Client
    // makes no sense as this contract has no ether.
    function withdraw() noEther {
        if (msg.sender != contractor || now < votingDeadline + payoutFreezePeriod)
            throw;
        uint timeSincelastWithdrawal = now - lastWithdrawal;
        // Calculate the amount using 1 second precision.
        uint amount = (timeSincelastWithdrawal * dailyWithdrawalLimit) / (1 days);
        if (amount > this.balance) {
            amount = this.balance;
        }
        var lastWithdrawalReset = lastWithdrawal;
        lastWithdrawal = now;
        if (!contractor.send(amount))
            lastWithdrawal = lastWithdrawalReset;
    }

    // Perform the withdrawal of the initial sum of money to the contractor
    // if that did not already happen during the signing
    function performInitialWithdrawal() noEther {
        if (msg.sender != contractor
            || now < votingDeadline + payoutFreezePeriod
            || initialWithdrawalDone ) {
            throw;
        }

        initialWithdrawalDone = true;
        if (!contractor.send(initialWithdrawal))
            throw;
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
