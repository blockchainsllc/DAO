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
Generic contract for a Decentralized Autonomous Organisation (DAO) to manage a trust
*/

import "./TokenSale.sol";
import "./ManagedAccount.sol";

contract DAOInterface {

    // proposals to spend ether of the DAO or choose a new service provider
    Proposal[] public proposals;
    // the minimal quorum needed for a proposal to vote is calculated by totalSupply / minQuorumDivisor
    uint minQuorumDivisor;
    // the time of the last proposal which has met the minimal quorum
    uint lastTimeMinQuorumMet;

    // to total amount of wei received as reward which has not been sent to the rewardAccount
    uint public rewards;

    // address of the service provider
    address public serviceProvider;
    // list of addresses the DAO is allowed to send money to
    address[] public allowedRecipients;

    // only used for splits, give DAOs without a balance the privilege to access their portion of the rewards
    // conceptually, reward token represents the right to receive rewards that arise from the already spent fund.
    mapping (address => uint) public rewardToken;
    // sum of all reward token
    uint public totalRewardToken;

    // account used to manage the rewards which are to be distributed to the
    // DAO Token Holders (and reward token holders) separately, so they don't appear in `this.balance`
    ManagedAccount public rewardAccount;
    // amount of wei already paid out to a certain member address
    mapping (address => uint) public paidOut;

    // deposit in wei to be held for each proposal
    uint public proposalDeposit;

    // contract which is able to create a new DAO (with the same code as this one), used for splits
    DAO_Creator public daoCreator;

    // A proposal with `newServiceProvider == false` represents a transaction issued by this DAO.
    // A proposal with `newServiceProvider == true` represents a DAO split proposal.
    struct Proposal {
        // The address where the `amount` will go to if the proposal is accepted
        // (if `newServiceProvider` is true, the proposed service provider of the new DAO).
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount;
        // A plain text description of the proposal
        string description;
        // A Unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal is open for voting, false if the votes have already been counted
        bool openToVote;
        // True if the sufficient votes have been counted with the majority saying yes.
        bool proposalPassed;
        // A hash to check validity of a proposal. Equal to sha3(_recipient, _amount, _transactionBytecode)
        bytes32 proposalHash;
        // The deposit in wei the creator puts in the proposal. Is taken from the msg.value of a newProposal call.
        uint proposalDeposit;
        // True if this proposal is to assign a new service provider
        bool newServiceProvider;
        // Data needed for splitting the DAO
        SplitData[] splitData;
        // Array holding all votes that have taken place on the proposal
        Vote[] votes;
        // Simple mapping to check if a token holder has already cast a vote
        mapping (address => bool) voted;
        // Address of the token holder who created the proposal
        address creator;
    }

    // Used only in the case of a newServiceProvider porposal.
    struct SplitData {
        // Is the balance of the current DAO minus the deposit at the time of split.
        uint splitBalance;
        // Represents the total amount of Tokens in existence at the time of split.
        uint totalSupply;
        // Amount of rewardToken owned by the DAO at the time of split.
        uint rewardToken;
        // the new DAO contract created at the time of split.
        DAO newDAO;
    }

    struct Vote {
        // True for 'yay', false for 'nay'
        bool inSupport;
        // The address of the voter
        address voter;
    }

    modifier onlyTokenholders {}

    /// @dev Constructor setting the default service provider and the address for the contract able
    ///      to create another DAO as well as the parameters for the DAO Token Sale
    /// @param _defaultServiceProvider The default service provider
    /// @param _daoCreator The contract able to (re)create this DAO
    /// @param _minValue Minimal value for a successful DAO Token Sale
    /// @param _closingTime Date (in unix time) of the end of the DAO Token Sale
    //  function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime)

    /// @notice Buy Token with `msg.sender` as the beneficiary as long as the DAO Token Sale is not closed, otherwise call receiveDAOReward().
    function () returns (bool success);

    /// @dev function used to receive rewards as the DAO
    /// @return Whether the call to this function was successful or not
    function receiveDAOReward() returns(bool);

    /// @notice `msg.sender` creates a proposal to send `_amount` Wei to `_recipient` with the transaction data `_transactionBytecode`.
    ///         (If `_newServiceProvider` is true, then this is a proposal that splits the DAO and sets `_recipient` as the new DAO's new service provider)
    /// @param _recipient The address of the recipient of the proposed transaction
    /// @param _amount The amount of wei to be sent with the proposed transaction
    /// @param _description A string describing the proposal
    /// @param _transactionBytecode The data of the proposed transaction
    /// @param _debatingPeriod The time used for debating the proposal, at least 2 weeks.
    /// @param _newServiceProvider A bool defining whether this proposal is about a new service provider or not
    /// @return The proposal ID. Needed for voting on the proposal
    function newProposal(address _recipient, uint _amount, string _description, bytes _transactionBytecode, uint _debatingPeriod, bool _newServiceProvider) onlyTokenholders returns (uint _proposalID);

    /// @notice Check that the proposal with the ID `_proposalID` matches a transaction which sends `_amount` with data `_transactionBytecode` to `_recipient`
    /// @param _proposalID The proposal ID
    /// @param _recipient The recipient of the proposed transaction
    /// @param _amount The amount of wei to be sent with the proposed transaction
    /// @param _transactionBytecode The data of the proposed transaction
    /// @return Whether the proposal ID matches the transaction data or not
    function checkProposalCode(uint _proposalID, address _recipient, uint _amount, bytes _transactionBytecode) constant returns (bool _codeChecksOut);

    /// @notice Vote on proposal `_proposalID` with `_supportsProposal`
    /// @param _proposalID The proposal ID
    /// @param _supportsProposal Yes/No - support of the proposal
    /// @return The vote ID.
    function vote(uint _proposalID, bool _supportsProposal) onlyTokenholders returns (uint _voteID);

    /// @notice Checks whether proposal `_proposalID` with transaction data `_transactionBytecode` has been voted for or rejected,
    ///         and executes the transaction in the case it has been voted for.
    /// @param _proposalID The proposal ID
    /// @param _transactionBytecode The data of the proposed transaction // TODO is this needed
    /// @return Whether the proposed transaction has been executed or not
    function executeProposal(uint _proposalID, bytes _transactionBytecode) returns (bool _success);

    /// @notice ATTENTION! I confirm to move my remaining funds to a new DAO with `_newServiceProvider` as the new service provider,
    ///         as has been proposed in proposal `_proposalID`. This will burn my tokens. This can not be undone and will split the
    ///         DAO into two DAO's, with two underlying tokens.
    /// @param _proposalID The proposal ID
    /// @param _newServiceProvider The new service provider of the new DAO
    /// @dev This function, when called for the first time for this proposal, will create a new DAO and send the portion of the remaining
    ///      funds which can be attributed to the sender to the new DAO. It will also burn the Tokens of the sender. (TODO: document rewardTokens)
    function confirmNewServiceProvider(uint _proposalID, address _newServiceProvider) returns (bool _success);

    /// @notice add new possible recipient `_recipient` for transactions from the DAO (through proposals)
    /// @param _recipient New recipient address
    /// @dev Can only be called by the current service provider
    function addAllowedAddress(address _recipient) external returns (bool _success);

    /// @notice change the deposit needed to make a proposal to `_proposalDeposit`
    /// @param _proposalDeposit New proposal deposit
    /// @dev Can only be called by this DAO (through proposals with its recipient being this DAO itself)
    function changeProposalDeposit(uint _proposalDeposit) external;

    /// @notice get my portion of the reward which has been sent to `rewardAccount`
    function getMyReward() external;


    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address indexed voter);
    event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
    event NewServiceProvider(address indexed _newServiceProvider);
    event AllowedRecipientAdded(address indexed _recipient);
}

// The DAO contract itself
contract DAO is DAOInterface, Token, TokenSale {

    // modifier that allows only token holders to vote and create new proposals
    modifier onlyTokenholders {
        if (balanceOf(msg.sender) == 0) throw;
            _
    }


    function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime, address _privateSale) TokenSale(_minValue, _closingTime, _privateSale) {
        serviceProvider = _defaultServiceProvider;
        daoCreator = _daoCreator;
        proposalDeposit = 20 ether;
        rewardAccount = new ManagedAccount(address(this));
        lastTimeMinQuorumMet = now;
        minQuorumDivisor = 5; // sets the minimal quorum to 20%
        if (address(rewardAccount) == 0) throw;
    }


    function () returns (bool success) {
        // The first clause is needed for a split DAO to receive its rewards of the parent DAO. The 40 days are a safety measure.
        // No new DAO can be created within this time, and in the case people accidentally send ether to the DAO Token Sale, it will bounce back in the buyTokenProxy function
        if (now > closingTime + 40 days)
            return receiveDAOReward();
        else
            return buyTokenProxy(msg.sender);
    }


    function receiveDAOReward() returns(bool) {
        rewards += msg.value;
        return true;
    }


    function newProposal(address _recipient, uint _amount, string _description, bytes _transactionBytecode, uint _debatingPeriod, bool _newServiceProvider) onlyTokenholders returns (uint _proposalID){
        // check sanity
        if (_newServiceProvider && (_amount != 0 || _transactionBytecode.length != 0 || _recipient == serviceProvider || msg.value > 0 || _debatingPeriod < 1 weeks)) {
            throw;
        }
        else if (!_newServiceProvider && (!isRecipientAllowed(_recipient) || (_debatingPeriod < 2 weeks))) throw;

        if (!funded || now < closingTime || (msg.value < proposalDeposit && !_newServiceProvider)) throw;

        if (_recipient == address(rewardAccount) && _amount > rewards) throw;

        _proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _amount, _transactionBytecode);
        p.votingDeadline = now + _debatingPeriod;
        p.openToVote = true;
        //p.proposalPassed = false; // that's default
        p.newServiceProvider = _newServiceProvider;
        if (_newServiceProvider)
            p.splitData.length++;
        p.creator = msg.sender;
        p.proposalDeposit = msg.value;
        ProposalAdded(_proposalID, _recipient, _amount, _description);
    }


    function checkProposalCode(uint _proposalID, address _recipient, uint _amount, bytes _transactionBytecode) noEther constant returns (bool _codeChecksOut) {
        Proposal p = proposals[_proposalID];
        return p.proposalHash == sha3(_recipient, _amount, _transactionBytecode);
    }


    function vote(uint _proposalID, bool _supportsProposal) onlyTokenholders noEther returns (uint _voteID) {
        Proposal p = proposals[_proposalID];
        if (p.voted[msg.sender] || now >= p.votingDeadline) throw;

        _voteID = p.votes.length++;
        p.votes[_voteID] = Vote({inSupport: _supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        Voted(_proposalID, _supportsProposal, msg.sender);
    }


    function executeProposal(uint _proposalID, bytes _transactionBytecode) noEther returns (bool _success) {
        Proposal p = proposals[_proposalID];
        // Check if the proposal can be executed
        if (now < p.votingDeadline  // has the voting deadline arrived?
            || !p.openToVote        // have the votes been counted?
            || p.newServiceProvider // new service provider proposal get confirmed not executed
            || p.proposalHash != sha3(p.recipient, p.amount, _transactionBytecode)) // Does the transaction code match the proposal?
            throw;

        // tally the votes
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i < p.votes.length; ++i) { //DANGER - unbound loop
            Vote v = p.votes[i];
            uint voteWeight = balanceOf(v.voter);
            if (v.inSupport)
                yea += voteWeight;
            else
                nay += voteWeight;
        }
        uint quorum = yea + nay;

        // execute result
        if (quorum >= minQuorum(p.amount) && yea > nay) {
            if (!p.creator.send(p.proposalDeposit)) throw;
            // Without this throw, the creator of the proposal can repeat this, and get so much fund.
            if (!p.recipient.call.value(p.amount)(_transactionBytecode)) throw;
            p.proposalPassed = true;
            _success = true;
            lastTimeMinQuorumMet = now;
            if (p.recipient == address(rewardAccount)) {
                // This happens when multiple similar proposals are created and both are passed at the same time.
                if (rewards < p.amount) throw;
                rewards -= p.amount;
            }
            else {
                rewardToken[address(this)] += p.amount;
                totalRewardToken += p.amount;
            }
        }
        else if (quorum >= minQuorum(p.amount) && nay >= yea) {
            if (!p.creator.send(p.proposalDeposit)) throw;
            lastTimeMinQuorumMet = now;
        }

        // Since the voting deadline is over, there is no point in counting again.
        p.openToVote = false;

        // Fire event.
        ProposalTallied(_proposalID, _success, quorum);
    }


    function confirmNewServiceProvider(uint _proposalID, address _newServiceProvider) noEther onlyTokenholders returns (bool _success) {
        Proposal p = proposals[_proposalID];

        // sanity check
        if (now < p.votingDeadline  // has the voting deadline arrived?
            || now > p.votingDeadline + 41 days
            || p.recipient != _newServiceProvider // Does the new service provider address match?
            || !p.newServiceProvider) // is it a new service provider proposal?
            throw;

        // if not already happened, create a new DAO and store the current split data
        if (address(p.splitData[0].newDAO) == 0) {
            p.splitData[0].newDAO = createNewDAO(_newServiceProvider);
            if (address(p.splitData[0].newDAO) == 0) throw; // Call depth limit reached, etc.
            if (this.balance < p.proposalDeposit) throw; // p.proposalDeposit should be zero here.
            p.splitData[0].splitBalance = this.balance - p.proposalDeposit;
            p.splitData[0].rewardToken = rewardToken[address(this)];
            p.splitData[0].totalSupply = totalSupply;
        }

        // move funds and assign new Tokens
        uint fundsToBeMoved = (balances[msg.sender] * p.splitData[0].splitBalance) / p.splitData[0].totalSupply;
        if (p.splitData[0].newDAO.buyTokenProxy.value(fundsToBeMoved)(msg.sender) == false) throw;


        // assign reward rights to new DAO
        uint rewardTokenToBeMoved = (balances[msg.sender] * p.splitData[0].rewardToken) / p.splitData[0].totalSupply;
        rewardToken[address(p.splitData[0].newDAO)] += rewardTokenToBeMoved;
        if (rewardToken[address(this)] < rewardTokenToBeMoved) throw;  // should not happen.
        rewardToken[address(this)] -= rewardTokenToBeMoved;

        // burn tokens
        Transfer(msg.sender, 0, balances[msg.sender]);
        totalSupply -= balances[msg.sender];
        balances[msg.sender] = 0;

        return true;
    }


    function getMyReward() noEther external {
        // my portion of the rewardToken of this DAO, or when called by a split child DAO, their portion of the rewardToken.
        uint myPortionOfTheReward = (balanceOf(msg.sender) * rewardToken[address(this)]) / totalSupply + rewardToken[msg.sender];
        uint myReward = (myPortionOfTheReward * rewardAccount.accumulatedInput()) / totalRewardToken - paidOut[msg.sender];
        if (!rewardAccount.payOut(msg.sender, myReward)) throw;
        paidOut[msg.sender] += myReward;
    }


    function transfer(address _to, uint256 _value) returns (bool success) {
        if (funded && now > closingTime && transferPaidOut(msg.sender, _to, _value) && super.transfer(_to, _value)){
            return true;
        }
        else throw;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (funded && now > closingTime && transferPaidOut(_from, _to, _value) && super.transferFrom(_from, _to, _value)){
            return true;
        }
        else throw;
    }


    function transferPaidOut(address _from, address _to, uint256 _value) internal returns (bool success){
        uint transferPaidOut = paidOut[_from] * _value / balanceOf(_from);
        if (transferPaidOut > paidOut[_from]) throw;
        paidOut[_from] -= transferPaidOut;
        paidOut[_to] += transferPaidOut;
        return true;
    }


    function changeProposalDeposit(uint _proposalDeposit) noEther external {
        if (msg.sender != address(this) || _proposalDeposit > this.balance / 10) throw;
        proposalDeposit = _proposalDeposit;
    }


    function addAllowedAddress(address _recipient) noEther external returns (bool _success) {
        if (msg.sender != serviceProvider) throw;
        allowedRecipients.push(_recipient);
        return true;
    }


    function isRecipientAllowed(address _recipient) internal returns (bool _isAllowed) {
        if (_recipient == serviceProvider || _recipient == address(rewardAccount) || _recipient == address(this))
            return true;
        for (uint i = 0; i < allowedRecipients.length; ++i) {
            if (_recipient == allowedRecipients[i])
                return true;
        }
        return false;
    }


    function minQuorum(uint _value) internal returns (uint _minQuorum) {
        return totalSupply / minQuorumDivisor + _value / 3;     // minimum of 20% and maximum of 53.33%
    }


    function halfMinQuorum() returns (bool _success){
        if (lastTimeMinQuorumMet < (now - 52 weeks)) {
            lastTimeMinQuorumMet = now;
            minQuorumDivisor *= 2;
            return true;
        }
        else
            return false;
    }


    function createNewDAO(address _newServiceProvider) internal returns (DAO _newDAO) {
        NewServiceProvider(_newServiceProvider);
        return daoCreator.createDAO(_newServiceProvider, 0, now + 42 days);
    }


    function numberOfProposals() constant returns (uint _numberOfProposals) {
        return proposals.length;
    }


    function numberOfVotes(uint _proposalID) constant returns (uint _numberOfVotes) {
        return proposals[_proposalID].votes.length;
    }
}

contract DAO_Creator {
    function createDAO(address _defaultServiceProvider, uint _minValue, uint _closingTime) returns (DAO _newDAO) {
        return new DAO(_defaultServiceProvider, DAO_Creator(this), _minValue, _closingTime, msg.sender);
    }
}
