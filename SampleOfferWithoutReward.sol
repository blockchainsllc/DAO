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


import "./ManagedAccount.sol";
import "./Token.sol";
import "./TokenCreation.sol";

// NOTE:
// Having customized DAO interface here because I am trying
// to circumvent this solidity bug:
// https://github.com/ethereum/solidity/issues/598
// by providing uint for all variable sized fields of the proposal
contract DAO is Token, TokenCreation {
    uint constant creationGracePeriod = 40 days;
    uint constant minProposalDebatePeriod = 2 weeks;
    uint constant minSplitDebatePeriod = 1 weeks;
    uint constant splitExecutionPeriod = 27 days;
    uint constant quorumHalvingPeriod = 25 weeks;
    uint constant executeProposalPeriod = 10 days;
    uint constant maxDepositDivisor = 100;

    Proposal[] public proposals;
    uint public minQuorumDivisor;
    uint public lastTimeMinQuorumMet;
    address public curator;
    mapping (address => bool) public allowedRecipients;
    mapping (address => uint) public rewardToken;
    uint public totalRewardToken;
    ManagedAccount public rewardAccount;
    ManagedAccount public DAOrewardAccount;
    mapping (address => uint) public DAOpaidOut;
    mapping (address => uint) public paidOut;
    mapping (address => uint) public blocked;
    uint public proposalDeposit;
    uint sumOfProposalDeposits;

    struct Proposal {
        address recipient;
        uint amount;

        uint description;

        uint votingDeadline;
        bool open;
        bool proposalPassed;
        bytes32 proposalHash;
        uint proposalDeposit;
        bool newCurator;

        uint splitData;

        uint yea;
        uint nay;

        uint votedYes;

        uint votedNo;

        address creator;
    }

    struct SplitData {
        uint splitBalance;
        uint totalSupply;
        uint rewardToken;
        DAO newDAO;
    }

    modifier onlyTokenholders {}

    function () returns (bool success);
    function receiveEther() returns(bool);
    function newProposal(
        address _recipient,
        uint _amount,
        string _description,
        bytes _transactionData,
        uint _debatingPeriod,
        bool _newCurator
    ) onlyTokenholders returns (uint _proposalID);

    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        uint _amount,
        bytes _transactionData
    ) constant returns (bool _codeChecksOut);
    function vote(
        uint _proposalID,
        bool _supportsProposal
    ) onlyTokenholders returns (uint _voteID);
    function executeProposal(
        uint _proposalID,
        bytes _transactionData
    ) returns (bool _success);
    function splitDAO(
        uint _proposalID,
        address _newCurator
    ) returns (bool _success);
    function newContract(address _newContract);
    function changeAllowedRecipients(address _recipient, bool _allowed) external returns (bool _success);
    function changeProposalDeposit(uint _proposalDeposit) external;
    function retrieveDAOReward(bool _toMembers) external returns (bool _success);
    function getMyReward() returns(bool _success);
    function withdrawRewardFor(address _account) internal returns (bool _success);
    function transferWithoutReward(address _to, uint256 _amount) returns (bool success);
    function transferFromWithoutReward(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success);

    function halveMinQuorum() returns (bool _success);
    function numberOfProposals() constant returns (uint _numberOfProposals);
    function getNewDAOAddress(uint _proposalID) constant returns (address _newDAO);
    function isBlocked(address _account) internal returns (bool);
    function unblockMe() returns (bool);

    event ProposalAdded(
        uint indexed proposalID,
        address recipient,
        uint amount,
        bool newCurator,
        string description
    );
    event Voted(uint indexed proposalID, bool position, address indexed voter);
    event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
    event NewCurator(address indexed _newCurator);
    event AllowedRecipientChanged(address indexed _recipient, bool _allowed);
}

contract SampleOfferWithoutReward {

    enum Method {
        RETURN_REMAINING_ETHER,
        UPDATE_CLIENT_ADDRESS
    }

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
    uint128 public minDailyWithdrawLimit;

    // The amount of money the Contractor has right to withdraw daily above the
    // initial withdraw. The Contractor does not have to do the withdraws every
    // day as this amount accumulates.
    uint128 public dailyWithdrawLimit;

    // The address of the Contractor.
    address public contractor;

    // The address of the Proposal/Offer document.
    bytes32 public IPFSHashOfTheProposalDocument;

    // The time of the last withdraw to the Contractor.
    uint public lastPayment;

    uint public dateOfSignature;
    DAO public client; // address of DAO
    DAO public originalClient; // address of DAO who signed the contract
    bool public isContractValid;
    // The required quorum for executing updateClientAddress
    // and returnRemainingEther, given at construction time. Has to be
    // a uint ranging from 0 to 100
    uint public quorumForChange;

    // -- only for debugging - start --
    uint public givenProposalID;
    bytes32 public givenHash;
    bytes32 public calculatedHash;
    uint public givenYea;
    uint public givenNay;
    bytes public calculatedTXDATA;
    // -- only for debugging - end --

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
        uint128 _minDailyWithdrawLimit,
        uint _quorumForChange
    ) {
        contractor = _contractor;
        originalClient = DAO(_client);
        client = DAO(_client);
        IPFSHashOfTheProposalDocument = _IPFSHashOfTheProposalDocument;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyWithdrawLimit = _minDailyWithdrawLimit;
        dailyWithdrawLimit = _minDailyWithdrawLimit;

        if (_quorumForChange > 100) {
            throw;
        }
        quorumForChange = _quorumForChange;
    }

    function requiredQuorumCheck(uint _proposalID, Method method) internal returns (bool _ok) {
        if (_proposalID > client.numberOfProposals()) {
            return false;
        }
        var (,,,,,proposalPassed, proposalHash,,,, yea, nay,,,) = client.proposals(_proposalID);
        uint quorum = (yea + nay) * 100 / client.totalSupply();
        var txData = new bytes(36);

        if (method == Method.RETURN_REMAINING_ETHER) { //0xbf51f24d
            txData[0] = 0xbf;
            txData[1] = 0x51;
            txData[2] = 0xf2;
            txData[3] = 0x4d;
        } else { // 0xf928662f
            txData[0] = 0xf9;
            txData[1] = 0x28;
            txData[2] = 0x66;
            txData[3] = 0x2f;
        }
        assembly { mstore(add(txData, 0x24), _proposalID) }

        bytes32 hash = sha3(
            address(this),
            0,
            txData
        );
        // -- only for debugging - start --
        givenHash = proposalHash;
        calculatedHash = hash;
        givenProposalID = _proposalID;
        givenYea = yea;
        givenNay = nay;
        calculatedTXDATA = txData;
        // -- only for debugging - end --
        return proposalPassed
            && hash == proposalHash
            && quorum >= quorumForChange;
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
        lastPayment = now;
    }

    function setDailyWithdrawLimit(uint128 _dailyWithdrawLimit) onlyClient noEther {
        if (_dailyWithdrawLimit >= minDailyWithdrawLimit)
            dailyWithdrawLimit = _dailyWithdrawLimit;
    }

    // "fire the contractor"
    function returnRemainingEther(uint _proposalID) onlyClient {
        if (!requiredQuorumCheck(_proposalID, Method.RETURN_REMAINING_ETHER)) {
            return;
        }
        if (originalClient.DAOrewardAccount().call.value(this.balance)())
            isContractValid = false;
    }

    // Withdraw to the Contractor.
    //
    // Withdraw the amount of money the Contractor has right to according to
    // the current withdraw limit.
    // Executing this function before the Offer is signed off by the Client
    // makes no sense as this contract has no money.
    function getDailyPayment() noEther {
        if (msg.sender != contractor)
            throw;
        uint timeSinceLastPayment = now - lastPayment;
        // Calculate the amount using 1 second precision.
        uint amount = (timeSinceLastPayment * dailyWithdrawLimit) / (1 days);
        if (amount > this.balance) {
            amount = this.balance;
        }
        if (contractor.send(amount))
            lastPayment = now;
    }

    // Change the client DAO by giving the new DAO's address
    // warning: The new DAO must come either from a split of the original
    // DAO or an update via `newContract()` so that it can claim rewards
    function updateClientAddress(DAO _newClient, uint _proposalID) onlyClient noEther {
        if (!requiredQuorumCheck(_proposalID, Method.UPDATE_CLIENT_ADDRESS)) {
            return;
        }
        client = _newClient;
    }

    function () {
        throw; // this is a business contract, no donations
    }
}
