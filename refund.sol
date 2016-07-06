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

// TODO: all constants need to be double checked
import "github.com/slockit/DAO/DAO.sol";
import "github.com/slockit/DAO/refundChild.sol";

contract Refund {
    ChildRefund public childRefund;
    uint constant public totalSupply = 11712722930974665882186911;
    uint constant public totalWeiSupply = 12072858342395652843028271;

    function withdraw(DAO _dao) {
        if (block.number < 0xfffff) throw; // to be replaced by HF block number
        if (address(childRefund) == 0)) {
            childRefund = new ChildRefund();
            if (!childRefund.send(174558484783966581114679) || address(childRefund) == 0) throw;
        }

        uint balance = _dao.balanceOf(msg.sender);

        if (!_dao.transferFrom(msg.sender, this, balance) || !msg.sender.send(balance * totalWeiSupply / totalSupply))
            throw;
    }
}
