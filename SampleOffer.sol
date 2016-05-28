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

    uint rewardDivisor;
    uint deploymentReward;

    function SampleOffer(
        address _contractor,
        address _client,
        bytes32 _hashOfTheProposalDocument,
        uint _totalCosts,
        uint _oneTimeCosts,
        uint128 _minDailyWithdrawLimit
    ) SampleOfferWithoutReward(
        _contractor,
        _client,
        _hashOfTheProposalDocument,
        _totalCosts,
        _oneTimeCosts,
        _minDailyWithdrawLimit) {
    }

    function setRewardDivisor(uint _rewardDivisor) onlyClient noEther {
        rewardDivisor = _rewardDivisor;
    }

    function setDeploymentReward(uint _deploymentReward) onlyClient noEther {
        deploymentReward = _deploymentReward;
    }

    // non-value-transfer getters
    function getRewardDivisor() noEther constant returns (uint) {
        return rewardDivisor;
    }

    function getDeploymentReward() noEther constant returns (uint) {
        return deploymentReward;
    }
}
