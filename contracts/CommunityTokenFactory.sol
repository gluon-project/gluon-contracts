import "./GluonToken.sol";
import "./CommunityToken.sol";

pragma solidity ^0.4.8;

contract CommunityTokenFactory {

    mapping(address => address[]) public created;
    mapping(address => bool) public isCommunityToken;
    GluonToken public gluonToken;


    function CommunityTokenFactory(address gluonAddress) {
        gluonToken = GluonToken(gluonAddress);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(msg.sender == address(gluonToken));
        CommunityToken newToken = this.call(_data); // _data should be encoded to call createCommunityToken. Maybe find a cleaner way to do this.
        // mint new tokens
        GluonToken.transfer(address(newToken), _value, 0x0);
        uint balance = newToken.balances[address(this)];
        // send minted tokens to user
        newToken.transfer(_from, balance, 0x0);
    }

    function createCommunityToken(string _name, uint8 _decimals, string _symbol) internal returns (CommunityToken) {
        // TODO - find correct value for reserveRatio and gasPrice, set dynamically?
        CommunityToken newToken = (new CommunityToken(100, address(gluonToken), 10000, _name, _decimals, _symbol));
        created[msg.sender].push(address(newToken));
        isCommunityToken[address(newToken)] = true;
        return newToken;
    }
}
