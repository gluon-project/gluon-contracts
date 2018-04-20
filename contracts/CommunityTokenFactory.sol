/*import "./GluonToken.sol";*/
/*import "./CommunityToken.sol";*/

/*pragma solidity ^0.4.8;*/

/*contract CommunityTokenFactory {*/

    /*mapping(address => address[]) public created;*/
    /*mapping(address => bool) public isCommunityToken;*/
    /*GluonToken public gluon;*/


    /*function CommunityTokenFactory(address gluonAddress) {*/
        /*gluon = GluonToken(gluonAddress);*/
    /*}*/

    /*function tokenFallback(address _from, uint _value, bytes _data) public {*/
        /*require(msg.sender == address(gluon));*/
        /*CommunityToken newToken = this.call(_data); // _data should be encoded to call createCommunityToken. Maybe find a cleaner way to do this.*/
        /*// mint new tokens*/
        /*gluon.transfer(address(newToken), _value, 0x0);*/
        /*uint balance = newToken.balances[address(this)];*/
        /*// send minted tokens to user*/
        /*newToken.transfer(_from, balance, 0x0);*/
    /*}*/

    /*function createCommunityToken(string _name, uint8 _decimals, string _symbol) internal returns (CommunityToken) {*/
        /*// TODO - find correct value for reserveRatio and gasPrice, set dynamically?*/
        /*CommunityToken newToken = (new CommunityToken(100, address(gluon), 10000, _name, _decimals, _symbol));*/
        /*created[msg.sender].push(address(newToken));*/
        /*isCommunityToken[address(newToken)] = true;*/
        /*return newToken;*/
    /*}*/

    /*function createWithEther(string _name, uint8 _decimals, string _symbol) public payable {*/
        /*CommunityToken newToken = this.createCommunityToken(_name, _decimals, _symbol);*/
        /*// buy gluons*/
        /*gluon.buy.value(msg.value)();*/
        /*// buy new token*/
        /*uint gluonBalance = gluon.balances[address(this)];*/
        /*gluon.transfer(address(newToken), gluonBalance, 0x0);*/
        /*// send minted tokens to user*/
        /*uint newTokenBalance = newToken.balances[address(this)];*/
        /*newToken.transfer(_from, newTokenBalance, 0x0);*/
    /*}*/
/*}*/
