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

contract DAOProxy {
    function proposals(uint _proposalID) returns(
        address recipient,
        uint amount,
        uint descriptionIdx,
        uint votingDeadline,
        bool open,
        bool proposalPassed,
        bytes32 proposalHash,
        uint proposalDeposit,
        bool newCurator
    );

    function transfer(address _to, uint256 _amount) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);

    function vote(
        uint _proposalID,
        bool _supportsProposal
    ) returns (uint _voteID);

    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract DTHPoolInterface {

    // name
    string public delegateName;

    // delegae url
    string public delegateUrl;

    // Max time the tokens can be blocked.
    // The real voting in the DAO will be called in the last moment in order
    // to block the tokens the minimum time. This parameter is the secons before
    // the voting period ends than the vote can be performed
    uint maxTimeBlocked;

    // How much balances each DTH has deposited in the pool
    mapping (address => uint256) public balanceOf;

    // Sum of all tokens deposited in the pool
    uint public totalPoolTokens;

    // Address of the delegate
    address public delegate;

    // The DAO contract
    DAOProxy public dao;

    struct ProposalStatus {

        // True when the delegate sets the vote
        bool voteSet;

        // True if the proposal should ve voted
        bool willVote;

        // True if the proposal should be accepted.
        bool suportProposal;

        // True when the vote is performed;
        bool executed;

        // Proposal votingDeadline
        uint votingDeadline;

        // String set by the delegator with the motivation
        string motivation;
    }

    // Statuses of the diferent proposal
    mapping (uint => ProposalStatus) public proposalStatuses;


    // List of proposals pending to vote
    uint[] public pendingProposals;


    /// @dev Constructor setting the dao address and the delegate
    /// @param _elegate adddress of the delegate.
    /// @param _valueDaos that will be transfered for delegation.
    /// @param _maxTimeBlocked the maximum time the tokens will blclocked
    // DTHPool(address _daoAddress, address _delegate, uint _maxTimeBlocked, string _delegateName, string _delegateUrl);

    /// @notice send votes to this contract.
    /// @param _amount Tokens that will be transfered to the pool.
    /// @return Whether the transfer was successful or not
    function delegateDAOTokens(uint _amount) returns (bool _success);

    /// Returns DAO tokens to the original
    /// @param _amount that will be transfered back to the owner.
    /// @return Whether the transfer was successful or not
    function undelegateDAOTokens(uint _amount) returns (bool _success);


    /// @notice This method will be called by the delegate to publish what will
    /// be his vote in a specific proposal.
    /// @param _proposalID The proposal to set the vote.
    /// @param _willVote true If the proposal will be voted.
    /// @param _supportsProposal What will be the vote.
    function setVoteIntention(uint _proposalID, bool _willVote, bool _supportsProposal, string _motivation) returns (bool _success);

    /// @notice This method will be do the actual voting in the DAO
    /// for the _proposalID
    /// @param _proposalID The proposal to set the vote.
    /// @return _finalized true if this vote Proposal must not be executed again.
    function executeVote(uint _proposalID) returns (bool _finalized);

    /// @notice Actually executes the votes if it remains less than 1 hour for
    /// the end of the voting period. This function must be called regularly
    /// before each proposal endDebatingTime.
    function executeAllVotes() returns (bool _success);


    /// @notice This function is intended because if some body sends tokens
    /// directly to this contract, this tokens can be sended to the delegate
    function fixTokens() returns (bool _success);


    /// @notice If some body sends ether to this contract, the delegate will be
    /// able to extract it.
    function getEther() returns (uint _amount);



    /// @notice Called when some body delegates token to the pool
    event Delegate(address indexed _from, uint256 _amount);

    /// @notice Called when some body undelegates token to the pool
    event Undelegate(address indexed _from, uint256 _amount);

    /// @notice Called when the delegate set se vote intention
    event VoteIntentionSet(uint indexed _proposalID, bool _willVote, bool _supportsProposal);

    /// @notice Called when the vote is executed in the DAO
    event VoteExecuted(uint indexed _proposalID);

}

contract DTHPool is DTHPoolInterface {

    modifier onlyDelegate() {if (msg.sender != delegate) throw; _}

    function DTHPool(address _daoAddress, address _delegate,  uint _maxTimeBlocked, string _delegateName, string _delegateUrl) {
        dao = DAOProxy(_daoAddress);
        delegate = _delegate;
        delegateName = _delegateName;
        delegateUrl = _delegateUrl;
        maxTimeBlocked = _maxTimeBlocked;
    }

    function delegateDAOTokens(uint _amount) returns (bool _success) {
        if (!dao.transferFrom(msg.sender, address(this), _amount)) {
            throw;
        }

        balanceOf[msg.sender] += _amount;
        totalPoolTokens += _amount;
        Delegate(msg.sender, _amount);
        return true;
    }

    function undelegateDAOTokens(uint _amount) returns (bool _success) {

        if (_amount > balanceOf[msg.sender]) throw;

        if (!dao.transfer(msg.sender, _amount)) {
            throw;
        }

        balanceOf[msg.sender] -= _amount;
        totalPoolTokens -= _amount;
        Undelegate(msg.sender, _amount);
        return true;
    }

    function setVoteIntention(uint _proposalID, bool _willVote, bool _supportsProposal, string _motivation) onlyDelegate returns (bool _success) {

        ProposalStatus proposalStatus = proposalStatuses[_proposalID];

        if (proposalStatus.voteSet) throw;

        var (,,,votingDeadline, ,,,,newCurator) = dao.proposals(_proposalID);

        if (votingDeadline < now) throw;
        if (newCurator) throw;

        proposalStatus.voteSet = true;
        proposalStatus.willVote = _willVote;
        proposalStatus.suportProposal = _supportsProposal;
        proposalStatus.votingDeadline = votingDeadline;
        proposalStatus.motivation = _motivation;

        if ( ! _willVote) {
            proposalStatus.executed = true;
            VoteExecuted(_proposalID);
        }

        VoteIntentionSet(_proposalID, _willVote, _supportsProposal);

        bool finalized = executeVote(_proposalID);

        if (!finalized) {
            pendingProposals[ pendingProposals.length++ ] = _proposalID;
        }

        return true;
    }

    function executeVote(uint _proposalID) returns (bool _finalized) {
        ProposalStatus proposalStatus = proposalStatuses[_proposalID];

        if (!proposalStatus.voteSet) return true;

        if ( now < proposalStatus.votingDeadline - maxTimeBlocked) return false;
        if ( now > proposalStatus.votingDeadline) return true;
        if ( ! proposalStatus.willVote) return true;
        if ( proposalStatus.executed) return true;

        dao.vote(_proposalID, proposalStatus.suportProposal);
        proposalStatus.executed = true;
        VoteExecuted(_proposalID);

        return true;
    }

    function executeAllVotes() returns (bool _success) {
        uint i;
        for (i=0; i<pendingProposals.length;) {
            bool finalized = executeVote(pendingProposals[i]);
            if (finalized) {
                pendingProposals[i] = pendingProposals[pendingProposals.length-1];
                pendingProposals.length --;
            } else {
                i++;
            }
        }
        return true;
    }

    function fixTokens() returns (bool _success) {
        uint ownedTokens = dao.balanceOf(this);

        if (ownedTokens < totalPoolTokens) throw;

        uint fixTokens = ownedTokens - totalPoolTokens;

        if (fixTokens == 0) return true;

        balanceOf[delegate] += fixTokens;
        totalPoolTokens += fixTokens;

        return true;
    }

    function getEther() onlyDelegate returns (uint _amount) {

        uint amount = this.balance;

        if (! delegate.call.value(amount)()) throw;

        return amount;
    }

}
