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
Generic contract for a Decentralized Autonomous Organisation (DAO) to manage 
a trust
*/

import "./TokenSale.sol";
import "./ManagedAccount.sol";

contract DAOInterface {

    // Proposals to spend the DAO's ether or to choose a new service provider
    Proposal[] public proposals;
    // The quorum needed for each proposal is partially calculated by 
    // totalSupply / minQuorumDivisor
    uint minQuorumDivisor;
    // The unix time of the last time quorum was reached on a proposal
    uint lastTimeMinQuorumMet;
    // The total amount of wei received as reward that has not been sent to 
    // the rewardAccount
    uint public rewards;
    // Address of the service provider
    address public serviceProvider;
    // The whitelist: List of addresses the DAO is allowed to send money to
    address[] public allowedRecipients;

    // Tracks the addresses that own Reward Tokens. Those addresses can only be 
    // DAOs that have split from the original DAO. Conceptually, Reward Tokens 
    // represent the proportion of the rewards that the DAO has the right to 
    // receive. These Reward Tokens are generated when the DAO spends ether.
    mapping (address => uint) public rewardToken;
    // Total supply of rewardToken
    uint public totalRewardToken;

    // The account used to manage the rewards which are to be distributed to the
    // DAO Token Holders of any DAO that holds Reward Tokens 
    ManagedAccount public rewardAccount;
    // Amount of rewards (in wei) already paid out to a certain address
    mapping (address => uint) public paidOut;
    // Map of addresses blocked during a vote (not allowed to transfer DAO  
    // tokens). The address points to the proposal ID.
    mapping (address => uint) public blocked;

    // Deposit in wei the creator added when submitting their proposal
    uint public proposalDeposit;

    // Contract that is able to create a new DAO (with the same code as 
    // this one), used for splits
    DAO_Creator public daoCreator;

    // A proposal with `newServiceProvider == false` represents a transaction 
    // to be issued by this DAO
    // A proposal with `newServiceProvider == true` represents a DAO split
    struct Proposal {
        // The address where the `amount` will go to if the proposal is accepted
        // or if `newServiceProvider` is true, the proposed service provider of 
        //the new DAO).
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount;
        // A plain text description of the proposal
        string description;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open;
        // True if quorum has been reached, the votes have been counted, and 
        // the majority said yes
        bool proposalPassed;
        // A hash to check validity of a proposal
        bytes32 proposalHash;
        // Deposit in wei the creator added when submitting their proposal. It 
        //is taken from the msg.value of a newProposal call.
        uint proposalDeposit;
        // True if this proposal is to assign a new service provider
        bool newServiceProvider;
        // Data needed for splitting the DAO
        SplitData[] splitData;
        // Number of tokens in favour of the proposal
        uint yea;
        // Number of tokens opposed to the proposal
        uint nay;
        // Simple mapping to check if a shareholder has voted for it
        mapping (address => bool) votedYes;
        // Simple mapping to check if a shareholder has voted against it
        mapping (address => bool) votedNo;
        // Address of the shareholder who created the proposal
        address creator;
    }

    // Used only in the case of a newServiceProvider porposal.
    struct SplitData {
        // The balance of the current DAO minus the deposit at the time of split
        uint splitBalance;
        // The total amount of DAO Tokens in existence at the time of split.
        uint totalSupply;
        // Amount of Reward Tokens owned by the DAO at the time of split.
        uint rewardToken;
        // The new DAO contract created at the time of split.
        DAO newDAO;
    }
    // Used to restrict acces to certain functions to only DAO Token Holders
    modifier onlyTokenholders {}

    /// @dev Constructor setting the default service provider and the address 
    /// for the contract able to create another DAO as well as the parameters 
    /// for the DAO Token Sale
    /// @param _defaultServiceProvider The default service provider
    /// @param _daoCreator The contract able to (re)create this DAO
    /// @param _minValue Minimal value for a successful DAO Token Sale
    /// @param _closingTime Date (in unix time) of the end of the DAO Token Sale
    /// @param _privateSale If zero the DAO Token Sale is open to public, a
    /// non-zero address means that the DAO Token Sale is only for the address
    // This is the constructor: it can not be overloaded so it is commented out
    //  function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime, address _privateSale)

    /// @notice Buy Token with `msg.sender` as the beneficiary as long as the 
    /// DAO Token Sale is not closed, otherwise call receiveDAOReward().
    function () returns (bool success);

    /// @dev Function used by the products of the DAO (e.g. Slocks) to send 
    /// rewards to the DAO
    /// @return Whether the call to this function was successful or not
    function payDAO() returns(bool);

    /// @dev Function used to receive ether the management of DAO Token Holders
    /// @return Whether the DAO received the ether successfully
    function receiveEther() returns(bool);

    /// @notice `msg.sender` creates a proposal to send `_amount` Wei to
    ///  `_recipient` with the transaction data `_transactionData`. If 
    /// `_newServiceProvider` is true, then this is a proposal that splits the 
    /// DAO and sets `_recipient` as the new DAO's new service provider.
    /// @param _recipient Address of the recipient of the proposed transaction
    /// @param _amount Amount of wei to be sent with the proposed transaction
    /// @param _description String describing the proposal
    /// @param _transactionData Data of the proposed transaction
    /// @param _debatingPeriod Time used for debating the proposal, at least 
    /// 2 weeks
    /// @param _newServiceProvider Bool defining whether this proposal is about 
    /// a new service provider or not
    /// @return The proposal ID. Needed for voting on the proposal
    function newProposal(
        address _recipient, 
        uint _amount, 
        string _description, 
        bytes _transactionData, 
        uint _debatingPeriod, 
        bool _newServiceProvider
    ) 
    onlyTokenholders 
    returns (uint _proposalID);

    /// @notice Check that the proposal with the ID `_proposalID` matches the 
    /// transaction which sends `_amount` with data `_transactionData` 
    /// to `_recipient`
    /// @param _proposalID The proposal ID
    /// @param _recipient The recipient of the proposed transaction
    /// @param _amount The amount of wei to be sent in the proposed transaction
    /// @param _transactionData The data of the proposed transaction
    /// @return Whether the proposal ID matches the transaction data or not
    function checkProposalCode(
        uint _proposalID, 
        address _recipient, 
        uint _amount, 
        bytes _transactionData,
        ) 
        constant 
        returns (bool _codeChecksOut);

    /// @notice Vote on proposal `_proposalID` with `_supportsProposal`
    /// @param _proposalID The proposal ID
    /// @param _supportsProposal Yes/No - support of the proposal
    /// @return The vote ID.
    function vote(uint _proposalID, bool _supportsProposal) 
        onlyTokenholders 
        returns (uint _voteID);

    /// @notice Checks whether proposal `_proposalID` with transaction data 
    /// `_transactionData` has been voted for or rejected, and executes the 
    /// transaction in the case it has been voted for.
    /// @param _proposalID The proposal ID
    /// @param _transactionData The data of the proposed transaction // TODO is this needed?
    /// @return Whether the proposed transaction has been executed or not
    function executeProposal(uint _proposalID, bytes _transactionData) 
        returns (bool _success);

    /// @notice ATTENTION! I confirm to move my remaining funds to a new DAO 
    /// with `_newServiceProvider` as the new service provider, as has been 
    /// proposed in proposal `_proposalID`. This will burn my tokens. This can 
    /// not be undone and will split the DAO into two DAO's, with two 
    /// different underlying tokens.
    /// @param _proposalID The proposal ID
    /// @param _newServiceProvider The new service provider of the new DAO
    /// @dev This function, when called for the first time for this proposal, 
    /// will create a new DAO and send the sender's portion of the remaining 
    /// ether and Reward Tokens to the new DAO. It will also burn the DAO Tokens
    /// of the sender. (TODO: document rewardTokens - done?)
    function splitDAO(
        uint _proposalID, 
        address _newServiceProvider
        ) 
        returns (bool _success);

    /// @notice Add a new possible recipient `_recipient` to the whitelist so 
    /// that the DAO can send transactions to them (using proposals)
    /// @param _recipient New recipient address
    /// @dev Can only be called by the current service provider
    function addAllowedAddress(address _recipient) 
        external 
        returns (bool _success);

    /// @notice Change the minimum deposit required to submit a proposal 
    /// @param _proposalDeposit The new proposal deposit
    /// @dev Can only be called by this DAO (through proposals with the 
    /// recipient being this DAO itself)
    function changeProposalDeposit(uint _proposalDeposit) external;

    /// @notice Get my portion of the reward that was sent to `rewardAccount`
    /// @return Whether the call was successful
    function getMyReward() returns(bool _success);

    /// @notice Withdraw `account`'s portion of the reward from `rewardAccount`,
    /// to `account`'s balance
    /// @return Whether the call was successful
    function withdrawRewardFor(address _account) returns(bool _success);

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`. Prior to this 
    /// getMyReward() is called.
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transfered
    /// @return Whether the transfer was successful or not
    function transferWithoutReward(address _to, uint256 _amount) 
        returns (bool success);

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it 
    /// is approved by `_from`. Prior to this getMyReward() is called.
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transfered
    /// @return Whether the transfer was successful or not
    function transferFromWithoutReward(
        address _from, 
        address _to, 
        uint256 _amount,
    ) 
        returns (bool success);

    /// @notice Doubles the 'minQuorumDivisor' in the case quorum has not been 
    /// achieved in 52 weeks
    /// @return Whether the change was successful or not
    function halveMinQuorum() returns (bool _success);


    event ProposalAdded(
        uint indexed proposalID, 
        address recipient, 
        uint amount, 
        bool newServiceProvider, 
        string description,
    );
    event Voted(uint indexed proposalID, bool position, address indexed voter);
    event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
    event NewServiceProvider(address indexed _newServiceProvider);
    event AllowedRecipientAdded(address indexed _recipient);
}

// The DAO contract itself
contract DAO is DAOInterface, Token, TokenSale {

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {
        if (balanceOf(msg.sender) == 0) throw;
            _
    }


    function DAO(
        address _defaultServiceProvider, 
        DAO_Creator _daoCreator, 
        uint _minValue, 
        uint _closingTime, 
        address _privateSale,
    ) 
        TokenSale(_minValue, _closingTime, _privateSale) 
    {
        serviceProvider = _defaultServiceProvider;
        daoCreator = _daoCreator;
        proposalDeposit = 20 ether;
        rewardAccount = new ManagedAccount(address(this));
        lastTimeMinQuorumMet = now;
        minQuorumDivisor = 5; // sets the minimal quorum to 20%
        proposals.length++; // avoids a proposal with ID 0 because it is used
        if (address(rewardAccount) == 0) throw;
    }


    function payDAO() returns (bool) {
        rewards += msg.value;
        return true;
    }

    function receiveEther() returns (bool) {
        return true;
    }


    function newProposal(
        address _recipient, 
        uint _amount, 
        string _description, 
        bytes _transactionData, 
        uint _debatingPeriod, 
        bool _newServiceProvider,
    ) 
        onlyTokenholders 
        returns (uint _proposalID)
    {
        // Sanity check
        if (_newServiceProvider && (
            _amount != 0 
            || _transactionData.length != 0 
            || _recipient == serviceProvider 
            || msg.value > 0 
            || _debatingPeriod < 1 weeks)) 
        {
            throw;
        }
        else if (!_newServiceProvider 
            && (!isRecipientAllowed(_recipient) || (_debatingPeriod < 2 weeks))
        ) 
            throw;

        if (!isFunded 
            || now < closingTime 
            || (msg.value < proposalDeposit && !_newServiceProvider)
        ) 
            throw;

        if (_recipient == address(rewardAccount) && _amount > rewards) throw;

        if (now + _debatingPeriod < now) throw; // preventing overflow

        _proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _amount, _transactionData);
        p.votingDeadline = now + _debatingPeriod;
        p.open = true;
        //p.proposalPassed = false; // that's default
        p.newServiceProvider = _newServiceProvider;
        if (_newServiceProvider)
            p.splitData.length++;
        p.creator = msg.sender;
        p.proposalDeposit = msg.value;
        ProposalAdded(
            _proposalID, 
            _recipient, 
            _amount, 
            _newServiceProvider, 
            _description,
        );
    }


    function checkProposalCode(
        uint _proposalID, 
        address _recipient, 
        uint _amount, 
        bytes _transactionData
    ) 
        noEther 
        constant 
        returns (bool _codeChecksOut) 
    {
        Proposal p = proposals[_proposalID];
        return p.proposalHash == sha3(_recipient, _amount, _transactionData);
    }


    function vote(uint _proposalID, bool _supportsProposal) 
        onlyTokenholders 
        noEther 
        returns (uint _voteID) 
    {
        Proposal p = proposals[_proposalID];
        if (p.votedYes[msg.sender] 
            || p.votedNo[msg.sender] 
            || now >= p.votingDeadline
        ) 
            throw;

        if (_supportsProposal){
            p.yea += balances[msg.sender];
            p.votedYes[msg.sender] = true;
        }
        else{
            p.nay += balances[msg.sender];
            p.votedNo[msg.sender] = true;
        }

        if (blocked[msg.sender] == 0)
            blocked[msg.sender] = _proposalID;
        // Check whether this proposal has a longer voting time left than  
        // another existing proposal voted on. (TODO: Make this comment clearer...)
        else if (
            p.votingDeadline > proposals[blocked[msg.sender]].votingDeadline
        )
            blocked[msg.sender] = _proposalID;

        Voted(_proposalID, _supportsProposal, msg.sender);
    }


    function executeProposal(uint _proposalID, bytes _transactionData) 
        noEther 
        returns (bool _success) 
    {
        Proposal p = proposals[_proposalID];
        // Check if the proposal can be executed
        if (now < p.votingDeadline  // has the voting deadline arrived?
            // Have the votes been counted?
            || !p.open       
            // Does the transaction code match the proposal?
            || p.proposalHash != sha3(p.recipient, p.amount, _transactionData)) 
            throw;

        if (p.newServiceProvider){
            p.open = false;
            return;
        }

        uint quorum = p.yea + p.nay;

        // Execute result
        if (quorum >= minQuorum(p.amount) && p.yea > p.nay) {
            if (!p.creator.send(p.proposalDeposit)) throw;
            // Without this throw, the creator of the proposal can repeat this, 
            // and get so much ether
            if (!p.recipient.call.value(p.amount)(_transactionData)) throw;
            p.proposalPassed = true;
            _success = true;
            lastTimeMinQuorumMet = now;
            if (p.recipient == address(rewardAccount)) {
                // This happens when multiple similar proposals are created and 
                // both are passed at the same time.
                if (rewards < p.amount) throw;
                rewards -= p.amount;
            }
            else {
                rewardToken[address(this)] += p.amount;
                totalRewardToken += p.amount;
            }
        }
        else if (quorum >= minQuorum(p.amount) && p.nay >= p.yea) {
            if (!p.creator.send(p.proposalDeposit)) throw;
            lastTimeMinQuorumMet = now;
        }

        // Since the voting deadline is over, don't count again.
        p.open = false;

        // Initiate event.
        ProposalTallied(_proposalID, _success, quorum);
    }


    function splitDAO(uint _proposalID, address _newServiceProvider) 
        noEther 
        onlyTokenholders 
        returns (bool _success) 
    {
        Proposal p = proposals[_proposalID];

        // Sanity check
        
        if (now < p.votingDeadline  // has the voting deadline arrived?
            //The request for a split expires 41 days after the voting deadline
            || now > p.votingDeadline + 41 days 
            // Does the new service provider address match?
            || p.recipient != _newServiceProvider 
            // Is it a new service provider proposal?
            || !p.newServiceProvider 
            // Have you voted for this split?
            || !p.votedYes[msg.sender] 
            // Did you already vote on another proposal?
            || blocked[msg.sender] != _proposalID) 
            throw;

        // If the new DAO doesn't exist yet, create the new DAO and store the 
        // current split data
        if (address(p.splitData[0].newDAO) == 0) {
            p.splitData[0].newDAO = createNewDAO(_newServiceProvider);
            // Call depth limit reached, etc.
            if (address(p.splitData[0].newDAO) == 0) throw; 
            // p.proposalDeposit should be zero here
            if (this.balance < p.proposalDeposit) throw; 
            p.splitData[0].splitBalance = this.balance - p.proposalDeposit;
            p.splitData[0].rewardToken = rewardToken[address(this)];
            p.splitData[0].totalSupply = totalSupply;
        }

        // Move funds and assign new Tokens
        uint fundsToBeMoved = 
            (balances[msg.sender] * p.splitData[0].splitBalance) 
            / p.splitData[0].totalSupply;
        if (
            p.splitData[0].newDAO.buyTokenProxy.value(fundsToBeMoved)(msg.sender) 
            == false
        ) 
            throw;


        // Assign reward rights to new DAO
        uint rewardTokenToBeMoved = 
            (balances[msg.sender] * p.splitData[0].rewardToken) 
            / p.splitData[0].totalSupply;
        rewardToken[address(p.splitData[0].newDAO)] += rewardTokenToBeMoved;
        if (rewardToken[address(this)] < rewardTokenToBeMoved) throw;  
        rewardToken[address(this)] -= rewardTokenToBeMoved;

        // Burn DAO Tokens
        Transfer(msg.sender, 0, balances[msg.sender]);
        totalSupply -= balances[msg.sender];
        balances[msg.sender] = 0;
        paidOut[address(p.splitData[0].newDAO)] += paidOut[msg.sender];
        paidOut[msg.sender] = 0;

        return true;
    }


    function getMyReward() noEther returns (bool _success) {
        return withdrawRewardFor(msg.sender);
    }


    function withdrawRewardFor(address _account) noEther returns (bool _success) {
        // The account's portion of Reward Tokens of this DAO
        uint portionOfTheReward = 
            (balanceOf(_account) * rewardToken[address(this)]) 
            / totalSupply + rewardToken[_account];
        uint reward = 
            (portionOfTheReward * rewardAccount.accumulatedInput()) 
            / totalRewardToken - paidOut[_account];
        if (!rewardAccount.payOut(_account, reward)) throw;
        paidOut[_account] += reward;
        return true;
    }


    function transfer(address _to, uint256 _value) returns (bool success) {
        if (isFunded 
            && now > closingTime 
            && !isBlocked(msg.sender) 
            && transferPaidOut(msg.sender, _to, _value) 
            && super.transfer(_to, _value)) 
        {
            return true;
        }
        else throw;
    }


    function transferWithoutReward(address _to, uint256 _value) 
        returns (bool success) 
    {
        if (!getMyReward()) throw;
        return transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success) 
    {
        if (isFunded 
            && now > closingTime 
            && !isBlocked(_from) 
            && transferPaidOut(_from, _to, _value) 
            && super.transferFrom(_from, _to, _value)) 
        {
            return true;
        }
        else throw;
    }


    function transferFromWithoutReward(
        address _from, 
        address _to, 
        uint256 _value,
    ) 
        returns (bool success) 
    {
        if (!withdrawRewardFor(_from)) throw;
        return transferFrom(_from, _to, _value);
    }


    function transferPaidOut(address _from, address _to, uint256 _value) 
        internal 
        returns (bool success) 
    {
        uint transferPaidOut = paidOut[_from] * _value / balanceOf(_from);
        if (transferPaidOut > paidOut[_from]) throw;
        paidOut[_from] -= transferPaidOut;
        paidOut[_to] += transferPaidOut;
        return true;
    }


    function changeProposalDeposit(uint _proposalDeposit) noEther external {
        if (msg.sender != address(this) || _proposalDeposit > this.balance / 10)
            throw;
        proposalDeposit = _proposalDeposit;
    }


    function addAllowedAddress(address _recipient) 
        noEther 
        external 
        returns (bool _success) 
    {
        if (msg.sender != serviceProvider) throw;
        allowedRecipients.push(_recipient);
        return true;
    }


    function isRecipientAllowed(address _recipient) 
        internal 
        returns (bool _isAllowed) 
    {
        if (_recipient == serviceProvider 
            || _recipient == address(rewardAccount) 
            || _recipient == address(this)
        )
            return true;
        for (uint i = 0; i < allowedRecipients.length; ++i) {
            if (_recipient == allowedRecipients[i])
                return true;
        }
        return false;
    }


    function minQuorum(uint _value) internal returns (uint _minQuorum) {
        // minimum of 20% and maximum of 53.33%
        return totalSupply / minQuorumDivisor + _value / 3;    
    }


    function halveMinQuorum() returns (bool _success){
        if (lastTimeMinQuorumMet < (now - 52 weeks)) {
            lastTimeMinQuorumMet = now;
            minQuorumDivisor *= 2;
            return true;
        }
        else
            return false;
    }


    function createNewDAO(address _newServiceProvider) 
        internal 
        returns (DAO _newDAO) 
    {
        NewServiceProvider(_newServiceProvider);
        return daoCreator.createDAO(_newServiceProvider, 0, now + 42 days);
    }


    function numberOfProposals() constant returns (uint _numberOfProposals) {
        // Don't count index 0. It's used by isBlocked() and exists from start
        return proposals.length - 1;
    }


    function isBlocked(address _account) returns (bool){
        if (blocked[_account] == 0) return false;
        Proposal p = proposals[blocked[_account]];
        if (!p.open){
            blocked[_account] = 0;
            return false;
        }
        else
            return true;
    }
}

contract DAO_Creator {
    function createDAO(
        address _defaultServiceProvider, 
        uint _minValue, 
        uint _closingTime,
    ) 
        returns (DAO _newDAO) 
    {
        return new DAO(
            _defaultServiceProvider, 
            DAO_Creator(this), 
            _minValue, 
            _closingTime, 
            msg.sender,
        );
    }
}
