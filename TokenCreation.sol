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
 * Token Creation contract, used by the DAO to create its tokens and initialize
 * its ether. Feel free to modify the divisor method to implement different
 * Token Creation parameters
*/

import "./Token.sol";
import "./ManagedAccount.sol";

contract TokenCreationInterface {

    // End of token creation, in Unix time
    uint public closingTime;
    // Minimum fueling goal of the token creation, denominated in tokens to
    // be created
    uint public minTokensToCreate;
    // True if the DAO reached its minimum fueling goal, false otherwise
    bool public isFueled;
    // For DAO splits - if parentDAO is 0, then it is a public token
    // creation, otherwise only the address stored in parentDAO is
    // allowed to create tokens
    address public parentDAO;
    // hold extra ether which has been sent after the DAO token
    // creation rate has increased
    ManagedAccount public extraBalance;

    /// @dev Constructor setting the minimum fueling goal and the
    /// end of the Token Creation
    /// @param _minTokensToCreate Minimum fueling goal in number of
    ///        Tokens to be created
    /// @param _closingTime Date (in Unix time) of the end of the Token Creation
    /// @param _privateCreation Zero means that the creation is public.  A
    /// non-zero address represents the only address that can create Tokens
    /// (the address can also create Tokens on behalf of other accounts)
    // This is the constructor: it can not be overloaded so it is commented out
    //  function TokenCreation(
        //  uint _minTokensTocreate,
        //  uint _closingTime,
        //  address _privateCreation
        //  string _tokenName,
        //  string _tokenSymbol,
        //  uint _decimalPlaces
    //  );

    /// @notice Create Token with `_tokenHolder` as the initial owner of the Token
    /// @param _tokenHolder The address of the Tokens's recipient
    /// @return Whether the token creation was successful
    function createTokenProxy(address _tokenHolder) returns (bool success);

    /// @notice Refund `msg.sender` in the case the Token Creation did
    /// not reach its minimum fueling goal
    function refund();

    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
}


contract TokenCreation is TokenCreationInterface, Token {
    function TokenCreation(
        uint _minTokensToCreate,
        uint _closingTime,
        address _parentDAO,
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimalPlaces) {

        closingTime = _closingTime;
        minTokensToCreate = _minTokensToCreate;
        parentDAO = _parentDAO;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalPlaces;
        
    }

    function createTokenProxy(address _tokenHolder) returns (bool success) {
        if (now < closingTime && msg.value > 0
            && (parentDAO == 0 || parentDAO == msg.sender)) {

            uint token = msg.value;
            balances[_tokenHolder] += token;
            totalSupply += token;
            CreatedToken(_tokenHolder, token);
            if (totalSupply >= minTokensToCreate && !isFueled) {
                isFueled = true;
                FuelingToDate(totalSupply);
            }
            return true;
        }
        throw;
    }

    function refund() noEther {
        if (now > closingTime && !isFueled && parentDAO == 0) {
            if (msg.sender.call.value(balances[msg.sender])()) {
                Refund(msg.sender, balances[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0;
            }
        }
    }
}
