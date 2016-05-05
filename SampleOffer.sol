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
Sample Proposal from a Contractor to the DAO. 
Feel free to use as a template for your own proposal.
*/

import "./DAO.sol";

contract SampleOffer {

    uint public totalCosts;
    uint public oneTimeCosts;
    uint public dailyCosts;


    address public contractor;
    bytes32 public hashOfTheTerms;
    uint public minDailyCosts;
    uint public paidOut;

    uint public dateOfSignature;
    DAO public client; // address of DAO

    bool public promiseValid;
    bool public isOpenSource;
    uint public rewardDivisor;
    uint public deploymentReward;

    modifier callingRestriction {
        if (promiseValid) {
            if (msg.sender != address(client))
                throw;
        } else if (msg.sender != contractor) {
                throw;
        }
        _
    }

    modifier onlyClient {
        if (msg.sender != address(client))
            throw;
        _
    }

    modifier onlyContractor {
        if (msg.sender != contractor)
            throw;
        _
    }

    function SampleOffer(
        address _contractor,
        bytes32 _hashOfTheTerms,
        uint _totalCosts,
        uint _oneTimeCosts,
        uint _minDailyCosts
    ) {
        contractor = _contractor;
        hashOfTheTerms = _hashOfTheTerms;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyCosts = _minDailyCosts;
        dailyCosts = _minDailyCosts;
    }

    function sign(bool expectsOpenSource) {
        if (msg.value < totalCosts || dateOfSignature != 0)
            throw;
        if (!contractor.send(oneTimeCosts))
            throw;
        if (expectsOpenSource && !isOpenSource)
            throw;
        client = DAO(msg.sender);
        dateOfSignature = now;
        promiseValid = true;
    }
    
    function promiseOpenSource() onlyContractor {
        isOpenSource = true;
    }

    function setDailyCosts(uint _dailyCosts) onlyClient {
        if (dailyCosts >= minDailyCosts)
            dailyCosts = _dailyCosts;
    }

    // "fire the contractor"
    function returnRemainingMoney() onlyClient {
        if (client.receiveEther.value(this.balance)())
            promiseValid = false;
    }

    function getDailyPayment() {
        if (msg.sender != contractor)
            throw;
        uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - paidOut;
        if (contractor.send(amount))
            paidOut += amount;
    }

    function setRewardDivisor(uint _rewardDivisor) callingRestriction {
        if (_rewardDivisor < 20)
            throw; // 5% is the default max reward
        rewardDivisor = _rewardDivisor;
    }

    function setDeploymentFee(uint _deploymentReward) callingRestriction {
        if (deploymentReward > 10 ether)
            throw; // TODO, set a max defined by Curator, or ideally oracle (set in euro)
        deploymentReward = _deploymentReward;
    }

    function updateClientAddress(DAO _newClient) callingRestriction {
        client = _newClient;
    }

    // interface for Ethereum Computer
    function payOneTimeReward() returns(bool) {
        if (msg.value < deploymentReward)
            throw;
        if (promiseValid) {
            if (client.DAOrewardAccount().call.value(msg.value)()) {
                return true;
            } else {
                throw;
            }
        } else {
            if (contractor.send(msg.value)) {
                return true;
            } else {
                throw;
            }
        }
    }

    // pay reward
    function payReward() returns(bool) {
        if (promiseValid) {
            if (client.DAOrewardAccount().call.value(msg.value)()) {
                return true;
            } else {
                throw;
            }
        } else {
            if (contractor.send(msg.value)) {
                return true;
            } else {
                throw;
            }
        }
    }
}
