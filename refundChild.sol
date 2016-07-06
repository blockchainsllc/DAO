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

contract ChildRefund {
    DAO constant public mother = 0xbb9bc244d798123fde783fcc1c72d3bb8c189413;
    mapping (address => bool) public whiteList;
    uint constant public totalSupply = 11712722930974665882186911;
    uint constant public totalWeiSupply = 12072858342395652843028271;
    uint constant public fixChildDAOsListTime = 1468057560; // 09.07.2016 - 11:46:00 CEST

    function ChildRefund(){
        // whitelist all childDAO except of attacker DAO (commented out)
        whiteList[0xd4fe7bc31cedb7bfb8a345f31e668033056b2728] = true;
        whiteList[0x2c19c7f9ae8b751e37aeb2d93a699722395ae18f] = true;
        whiteList[0x1975bd06d486162d5dc297798dfc41edd5d160a7] = true;
        whiteList[0x319f70bab6845585f412ec7724b744fec6095c85] = true;
        whiteList[0x5c8536898fbb74fc7445814902fd08422eac56d0] = true;
        whiteList[0x779543a0491a837ca36ce8c635d6154e3c4911a6] = true;
        whiteList[0x5c6e67ccd5849c0d29219c4f95f1a7a93b3f5dc5] = true;
        whiteList[0x200450f06520bdd6c527622a273333384d870efb] = true;
        whiteList[0x6b0c4d41ba9ab8d8cfb5d379c69a612f2ced8ecb] = true;
        whiteList[0xd1ac8b1ef1b69ff51d1d401a476e7e612414f091] = true;
        
        whiteList[0x51e0ddd9998364a2eb38588679f0d2c42653e4a6] = true;
        whiteList[0xf0b1aa0eb660754448a7937c022e30aa692fe0c5] = true;
        whiteList[0x9f27daea7aca0aa0446220b98d028715e3bc803d] = true;
        whiteList[0xd9aef3a1e38a39c16b31d1ace71bca8ef58d315b] = true;
        whiteList[0x6f6704e5a10332af6672e50b3d9754dc460dfa4d] = true;
        whiteList[0x492ea3bb0f3315521c31f273e565b868fc090f17] = true;
        whiteList[0x9ea779f907f0b315b364b0cfc39a0fde5b02a416] = true;
        whiteList[0xcc34673c6c40e791051898567a1222daf90be287] = true;
        whiteList[0xe308bd1ac5fda103967359b2712dd89deffb7973] = true;
        whiteList[0xac1ecab32727358dba8962a0f3b261731aad9723] = true;
        
        whiteList[0x440c59b325d2997a134c2c7c60a8c61611212bad] = true;
        whiteList[0x9c15b54878ba618f494b38f0ae7443db6af648ba] = true;
        whiteList[0x21c7fdb9ed8d291d79ffd82eb2c4356ec0d81241] = true;
        whiteList[0x1ca6abd14d30affe533b24d7a21bff4c2d5e1f3b] = true;
        whiteList[0x6131c42fa982e56929107413a9d526fd99405560] = true;
        whiteList[0x542a9515200d14b68e934e9830d91645a980dd7a] = true;
        whiteList[0x782495b7b3355efb2833d56ecb34dc22ad7dfcc4] = true;
        whiteList[0x3ba4d81db016dc2890c81f3acec2454bff5aada5] = true;
        whiteList[0xe4ae1efdfc53b73893af49113d8694a057b9c0d1] = true;
        whiteList[0x0737a6b837f97f46ebade41b9bc3e1c509c85c53] = true;
        
        whiteList[0x52c5317c848ba20c7504cb2c8052abd1fde29d03] = true;
        whiteList[0x5d2b2e6fcbe3b11d26b525e085ff818dae332479] = true;
        whiteList[0x057b56736d32b86616a10f619859c6cd6f59092a] = true;
    //    whiteList[0x304a554a310c7e546dfe434669c62820b7d83490] = true;
        whiteList[0x4deb0033bb26bc534b197e61d19e0733e5679784] = true;
        whiteList[0x35a051a0010aba705c9008d7a7eff6fb88f6ea7b] = true;
        whiteList[0x9da397b9e80755301a3b32173283a91c0ef6c87e] = true;
        whiteList[0x0101f3be8ebb4bbd39a2e3b9a3639d4259832fd9] = true;
        whiteList[0xbcf899e6c7d9d5a215ab1e3444c86806fa854c76] = true;
        whiteList[0xa2f1ccba9395d7fcb155bba8bc92db9bafaeade7] = true;
        
        whiteList[0xd164b088bd9108b60d0ca3751da4bceb207b0782] = true;
        whiteList[0x1cba23d343a983e9b5cfd19496b9a9701ada385f] = true;
        whiteList[0x9fcd2deaff372a39cc679d5c5e4de7bafb0b1339] = true;
        whiteList[0x0e0da70933f4c7849fc0d203f5d1d43b9ae4532d] = true;
        whiteList[0xbc07118b9ac290e4622f5e77a0853539789effbe] = true;
        whiteList[0xacd87e28b0c9d1254e868b81cba4cc20d9a32225] = true;
        whiteList[0x5524c55fb03cf21f549444ccbecb664d0acad706] = true;
    //    whiteList[0xfe24cdd8648121a43a7c86d289be4dd2951ed49f] = true;
        whiteList[0x253488078a4edf4d6f42f113d1e62836a942cf1a] = true;
    //    whiteList[0xb136707642a4ea12fb4bae820f03d2562ebff487] = true;
        
        whiteList[0xf14c14075d6c4ed84b86798af0956deef67365b5] = true;
    //    whiteList[0xaeeb8ff27288bdabc0fa5ebb731b6f409507516c] = true;
        whiteList[0x6d87578288b6cb5549d5076a207456a1f6a63dc0] = true;
        whiteList[0xaccc230e8a6e5be9160b8cdf2864dd2a001c28b6] = true;
    //    whiteList[0x4613f3bca5c44ea06337a9e439fbc6d42e501d0a] = true;
    //    whiteList[0x84ef4b2357079cd7a7c69fd7a37cd0609a679106] = true;
    //    whiteList[0xf4c64518ea10f995918a454158c6b61407ea345c] = true;
    }

    function withdraw(DAO _dao) {
        if (!whiteList[address(_dao)]
            || _dao.lastTimeMinQuorumMet() > fixChildDAOsListTime
            || _dao.privateCreation() != mother)
            throw;

        uint balance = _dao.balanceOf(msg.sender);

        if (!_dao.transferFrom(msg.sender, this, balance) || !msg.sender.send(balance * totalWeiSupply / totalSupply))
            throw;
    }
}
