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
By default, token purchases can be executed on behalf of another address using the TokenSale.sol buyTokenProxy() function
This contract is used as a fall back in case an exchange doesn't implement the "add data to a transaction" feature in a timely manner, preventing it from calling buyTokenProxy().
Calling this contract automatically triggers a call to buyTokenProxy() using the correct parameters for a given participant in the token sale.
A unique instance of such a contract would have to be deployed per participant, usually using a middleware layer on a webserver, for example.
*/

import "./TokenSale.sol";

contract DAOTokenSaleProxyTransferer {
    address public owner;
    address public dao;

    //constructor
    function DAOTokenSaleProxyTransferer(address _owner, address _dao) {
        owner = _owner;
        dao = _dao;

        // just in case somebody already added values to this address, we will forward it right now.
        sendValues();
    }

    // default-function called when values are sent.
    function () {
       sendValues();
    }

    function sendValues() {
        if (this.balance == 0)
            return;

        TokenSaleInterface funding = TokenSaleInterface(dao);
        if (now > funding.closingTime() ||
            !funding.buyTokenProxy.value(this.balance)(owner)) {

           owner.send(this.balance);
        }
    }
}
