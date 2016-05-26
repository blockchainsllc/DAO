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
  Sample Proposal from a Contractor to the DAO including a reward towards the
  DAO.

  Feel free to use as a template for your own proposal.
*/

import "./SampleOfferWithoutReward.sol";

contract SampleOffer is SampleOfferWithoutReward {

    uint public rewardDivisor;
    uint public deploymentReward;

        function SampleOffer(
            address _contractor,
            address _client,
            bytes32 _IPFSHashOfTheProposalDocument,
            uint _totalCosts,
            uint _oneTimeCosts,
            uint128 _minDailyWithdrawLimit,
            uint _quorumForChange
        ) SampleOfferWithoutReward(
            _contractor,
            _client,
            _IPFSHashOfTheProposalDocument,
            _totalCosts,
            _oneTimeCosts,
            _minDailyWithdrawLimit,
            _quorumForChange) {
        }

    function setRewardDivisor(uint _rewardDivisor) onlyClient noEther {
        rewardDivisor = _rewardDivisor;
    }

    function setDeploymentReward(uint _deploymentReward) onlyClient noEther {
        deploymentReward = _deploymentReward;
    }

    // interface for Ethereum Computer
    function payOneTimeReward() returns(bool) {
        // client DAO should not be able to pay itself generating
        // "free" reward tokens
        if (msg.sender == address(client) || msg.sender == address(originalClient))
            throw;

        if (msg.value < deploymentReward)
            throw;

        if (originalClient.DAOrewardAccount().call.value(msg.value)()) {
            return true;
        } else {
            throw;
        }
    }

    // pay reward
    function payReward() returns(bool) {
        // client DAO should not be able to pay itself generating
        // "free" reward tokens
        if (msg.sender == address(client) || msg.sender == address(originalClient))
            throw;

        if (originalClient.DAOrewardAccount().call.value(msg.value)()) {
            return true;
        } else {
            throw;
        }
    }
}
