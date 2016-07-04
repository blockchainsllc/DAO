/*

CODE TO MAKE THE DAO INTO AN AUTOMATIC REFUND

*/
// A generic token contract
contract token { 
    mapping (address => uint256) public balanceOf;  
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function mintToken(address target, uint256 mintedAmount);
    uint256 public totalSupply;
}


/* define 'owned' */
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract DAORefund is owned {
    // address of original DAO
    token DAOTokens;
    
    // Address of new refund token (can be used to claim any additional eventual refund in the future)
    token DAOBadgeOfHonor;
    
    // the price it will refund it for
    uint public weiRefundedPerToken;

    /* First time setup */
    function DAORefund(address DAOAddress, address BOHAddress) {
        DAOTokens = token(DAOAddress);
        DAOBadgeOfHonor = token(BOHAddress);
    }
    
    // to be called by the owner to lock the price so it guarantees all tokens are refunded the same
    function setPrice() onlyOwner {
        uint tokenSupply = DAOTokens.totalSupply() - DAOTokens.balanceOf(this);
        weiRefundedPerToken = this.balance / tokenSupply;
    }
    
    // allows tokens to be refunded by ether and badges of honors to be sent back
    function convertTokens(uint amountOfTokens) {
        if (weiRefundedPerToken == 0
        || !DAOTokens.transferFrom(msg.sender, address(this), amountOfTokens)) 
            throw;
        
        // do these last to avoid a recursion attack
        DAOBadgeOfHonor.mintToken(msg.sender, amountOfTokens);
        msg.sender.send(amountOfTokens * weiRefundedPerToken);
    }

    // Allows the refund contract on doing any actions except token transfers
    function execute(address _target, bytes _data) onlyOwner  {
        if (_target == address(DAOTokens) && _data.length >= 4 &&
            //do not allow any token transfer related actions on the DAO
            ( // 0x095ea7b3: approve()
                (_data[0] == 0x09 && _data[1] == 0x5e
                 && _data[2] == 0xa7 && _data[3] == 0xb3))
            || ( // 0xa9059cbb: transfer(address,uint256)
                (_data[0] == 0xa9 && _data[1] == 0x05
                 && _data[2] == 0x9c && _data[3] == 0xbb))
            || ( // 0x4e10c3ee: transferWithoutReward(address,uint256)
                (_data[0] == 0x4e && _data[1] == 0x10
                 && _data[2] == 0xc3 && _data[3] == 0xee))
            || ( // 0x23b872dd: transferFrom(address,address,uint256)
                (_data[0] == 0x23 && _data[1] == 0xb8
                 && _data[2] == 0x72 && _data[3] == 0xdd))
            || ( // 0xdbde1988: transferFromWithoutReward(address,address,uint256)
                (_data[0] == 0xdb && _data[1] == 0xde
                 && _data[2] == 0x19 && _data[3] == 0x88))
        ) {
            throw;
        }

        _target.call.value(0)(_data);
    }
    
    // if price is already set, then don't accept any extra money
    function () {
        if (weiRefundedPerToken != 0) throw;
    }
}
