import "bytes/BytesLib.sol";
import "./EthCommunityToken.sol";
import "./CommunityToken.sol";
import "./ERC20Token.sol";

pragma solidity ^0.4.8;

contract CommunityTokenFactory {
    using BytesLib for bytes;

    address[] public createdTokens;
    mapping(address => bool) public isCommunityToken;
    EthCommunityToken public gluon;

    event TokenCreated(string name, address addr);

    function CommunityTokenFactory(address gluonAddress) {
        gluon = EthCommunityToken(gluonAddress);
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

    function createEthCommunityToken(string _name, uint8 _decimals, string _symbol, uint8 exponent) public returns (EthCommunityToken) {
        // TODO - find correct value for reserveRatio and gasPrice, set dynamically?
        EthCommunityToken newToken = new EthCommunityToken(_name, _decimals, _symbol, exponent);
        createdTokens.push(address(newToken));
        isCommunityToken[address(newToken)] = true;
        emit TokenCreated(_name, address(newToken));
        return newToken;
    }

    function createEthCommunityTokenAndMint(string _name, uint8 _decimals, string _symbol, uint8 exponent, uint256 numTokens) public payable returns (EthCommunityToken) {
        EthCommunityToken newToken = createEthCommunityToken(_name, _decimals, _symbol, exponent);
        newToken.mint.value(msg.value)(numTokens);
        bytes memory empty;
        newToken.transfer(msg.sender, numTokens, empty);
        return newToken;
    }

    function createERC20Token(string _name, uint8 _decimals, string _symbol, uint256 _totalSupply)  public returns (ERC20Token) {
        ERC20Token newToken = new ERC20Token(_name, _decimals, _symbol, _totalSupply);
        newToken.transfer(msg.sender, _totalSupply);
        createdTokens.push(address(newToken));
        emit TokenCreated(_name, address(newToken));
        return newToken;
    }

    function getNumberOfCreatedTokens() public view returns(uint256) {
        return createdTokens.length;
    }
}
