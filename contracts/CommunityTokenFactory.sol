import "bytes/BytesLib.sol";
import "./GluonToken.sol";
import "./CommunityToken.sol";

pragma solidity ^0.4.8;

contract CommunityTokenFactory {
    using BytesLib for bytes;

    address[] public createdTokens;
    mapping(address => bool) public isCommunityToken;
    GluonToken public gluon;

    event TokenCreated(string name, address addr);

    function CommunityTokenFactory(address gluonAddress) {
        gluon = GluonToken(gluonAddress);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(msg.sender == address(gluon));
        bytes memory numTokens = _data.slice(0, 32);
        bytes memory tokenData = _data.slice(32, _data.length - 32);

        // create new token
        require(address(this).call(bytes4(keccak256("createCommunityToken(string,uint8,string,uint8)")), tokenData));
        CommunityToken newToken = CommunityToken(createdTokens[createdTokens.length - 1]);
        // mint new tokens
        gluon.transfer(address(newToken), _value, numTokens);
        // send minted tokens to user
        bytes memory empty;
        newToken.transfer(_from, numTokens.toUint(0), empty);
    }

    function createCommunityToken(string _name, uint8 _decimals, string _symbol, uint8 exponent) public returns (CommunityToken) {
        // TODO - find correct value for reserveRatio and gasPrice, set dynamically?
        CommunityToken newToken = new CommunityToken(_name, _decimals, _symbol, exponent, address(gluon));
        createdTokens.push(address(newToken));
        isCommunityToken[address(newToken)] = true;
        emit TokenCreated(_name, address(newToken));
        return newToken;
    }

    function getNumberOfCreatedTokens() public view returns(uint256) {
        return createdTokens.length;
    }
}
