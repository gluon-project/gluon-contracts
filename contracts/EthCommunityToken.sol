pragma solidity ^0.4.18;

import "zeppelin/contracts/ownership/Ownable.sol";
import "./ERC223_Token.sol";


/**
 * @title Gluon Token
 */
contract EthCommunityToken is ERC223Token, Ownable {

    uint256 public poolBalance;

    uint8 public exponent;

    function EthCommunityToken(
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint8 _exponent
    ) public payable {
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        exponent = _exponent;
    }

    // TODO - this should be located in an external contract so the curve can be switched out
    function curveIntegral(uint256 t) internal returns (uint256) {
        uint256 one = 10000000000;
        uint256 nexp = exponent + 1;
        uint256 x = t ** nexp;
        // TODO - check for overflow in power function
        return one.div(nexp).mul(x).div(one);
    }

    function priceToMint(uint256 numTokens) public returns(uint256) {
        return curveIntegral(totalSupply + numTokens) - poolBalance;
    }

    function rewardForBurn(uint256 numTokens) public returns(uint256) {
        return poolBalance - curveIntegral(totalSupply - numTokens);
    }

    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        totalSupply = totalSupply.add(numTokens);
        balances[msg.sender] = balances[msg.sender].add(numTokens);
        poolBalance = poolBalance.add(msg.value);
        // TODO - send back any additional ether
        emit Minted(numTokens, msg.value);
    }

    function burn(uint256 numTokens) public {
        require(balances[msg.sender] >= numTokens);
        uint256 ethToReturn = rewardForBurn(numTokens);
        totalSupply = totalSupply.sub(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        poolBalance = poolBalance.sub(ethToReturn);
        msg.sender.transfer(ethToReturn);

        emit Burned(numTokens, ethToReturn);
    }

    event Minted(uint256 amount, uint256 totalCost);
    event Burned(uint256 amount, uint256 reward);
}
