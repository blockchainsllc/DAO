import "./SampleOffer.sol";


contract USNRewardPayOut {
     
     SampleOffer public usnContract;
     
     function USNRewardPayOut(SampleOffer _usnContract) {
          usnContract = _usnContract;
     }

     // interface for USN
    function payOneTimeReward() returns(bool) {
        if (msg.value < usnContract.getDeploymentReward())
            throw;

          if (usnContract.getOriginalClient().DAOrewardAccount().call.value(msg.value)()) {
            return true;
        } else {
            throw;
        }
    }

    // pay reward
    function payReward() returns(bool) {
          if (usnContract.getOriginalClient().DAOrewardAccount().call.value(msg.value)()) {
            return true;
        } else {
            throw;
        }
    }
}
