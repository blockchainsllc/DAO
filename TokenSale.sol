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
Token Sale contract, used by the DAO to sell its tokens and initialize its ether.
Feel free to modify the divisor method to implement different Token sale parameters 
*/

import "./Token.sol";
import "./ManagedAccount.sol";

contract TokenSaleInterface {

    // End of token sale, in Unix time
    uint public closingTime;
    // Minimum fueling goal of the token sale, denominated in ether
    uint public minValue;
    // True if the DAO reached its minimum fueling goal, false otherwise
    bool public isFunded;
    // For DAO splits - if privateSale is 0, then it is a public sale, otherwise
    // only the address stored in privateSale is allowed to purchase tokens
    address public privateSale;
    // hold extra ether which has been paid after the DAO token price has increased
    ManagedAccount public extraBalance;
    // tracks the amount of wei given from each contributor (used for refund)
    mapping (address => uint256) weiGiven;

    /// @dev Constructor setting the minimum fueling goal and the
    /// end of the Token Sale
    /// @param _minValue Token Sale minimum fueling goal
    /// @param _closingTime Date (in Unix time) of the end of the Token Sale
    /// @param _privateSale Zero means that the sale is public.  A non-zero
    /// address represents the only address that can buy Tokens (the address
    /// can also buy Tokens on behalf of other accounts)
    // This is the constructor: it can not be overloaded so it is commented out
    //  function TokenSale(
        //  uint _minValue,
        //  uint _closingTime,
        //  address _privateSale
    //  );

    /// @notice Buy Token with `_tokenHolder` as the initial owner of the Token
    /// @param _tokenHolder The address of the Tokens's recipient
    /// @return Whether the purchase was successful
    function buyTokenProxy(address _tokenHolder) returns (bool success);

    /// @notice Refund `msg.sender` in the case the Token Sale didn't reach its
    /// minimum fueling goal
    function refund();

    /// @return The divisor used to calculate the token price during the sale
    function divisor() returns (uint divisor);

    event FundingToDate(uint value);
    event SoldToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
}


contract TokenSale is TokenSaleInterface, Token {
    function TokenSale(uint _minValue, uint _closingTime, address _privateSale) {
        closingTime = _closingTime;
        minValue = _minValue;
        privateSale = _privateSale;
        extraBalance = new ManagedAccount(address(this));
    }

    function buyTokenProxy(address _tokenHolder) returns (bool success) {
        if (now < closingTime && msg.value > 0
            && (privateSale == 0 || privateSale == msg.sender)) {

            uint token = (msg.value * 20) / divisor();
            extraBalance.call.value(msg.value - token)();
            balances[_tokenHolder] += token;
            totalSupply += token;
            weiGiven[_tokenHolder] += msg.value;
            SoldToken(_tokenHolder, token);
            if (totalSupply >= minValue && !isFunded) {
                isFunded = true;
                FundingToDate(totalSupply);
            }
            return true;
        }
        throw;
    }

    function refund() noEther {
        if (now > closingTime && !isFunded) {
            // Get extraBalance - will only succeed when called for the first time
            extraBalance.payOut(address(this), extraBalance.accumulatedInput());

            // Execute refund
            if (msg.sender.call.value(weiGiven[msg.sender])()) {
                Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0;
                weiGiven[msg.sender] = 0;
            }
        }
    }

    function divisor() returns (uint divisor) {
        // The number of (base unit) tokens per wei is calculated
        // as `msg.value` * 20 / `divisor`
        // The fueling period starts with a 1:1 ratio
        if (closingTime - 2 weeks > now) {
            return 20;
        // Followed by 10 days with a daily price increase of 5%
        } else if (closingTime - 4 days > now) {
            return (20 + (now - (closingTime - 2 weeks)) / (1 days));
        // The last 4 days there is a constant price ratio of 1:1.5
        } else {
            return 30;
        }
    }
}
