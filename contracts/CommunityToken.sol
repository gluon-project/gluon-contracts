pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "bytes/BytesLib.sol";
import "./ERC223_Token.sol";


/**
 * @title Gluon Token
 * @dev Bonding curve contract based on Bacor formula
 * inspired by bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 */
contract CommunityToken is ERC223Token, Ownable {
    using BytesLib for bytes;

    ERC223Token public reserveToken;
    uint256 public poolBalance;
    uint8 public exponent;

    function CommunityToken(
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint8 _exponent,
        address _reserveToken
    ) public {
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        exponent = _exponent;
        reserveToken = ERC223Token(_reserveToken);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(msg.sender == address(reserveToken));
        uint256 numTokens = _data.toUint(0);
        mint(_from, _value, numTokens);
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

    function mint(address sender, uint256 value, uint256 numTokens) internal {
        uint256 priceForTokens = priceToMint(numTokens);
        require(value >= priceForTokens);

        totalSupply = totalSupply.add(numTokens);
        balances[sender] = balances[sender].add(numTokens);
        poolBalance = poolBalance.add(value);
        // TODO - send back any additional tokens
        emit Minted(numTokens, value);
    }

    function burn(uint256 numTokens, bytes _data) public {
        require(balances[msg.sender] >= numTokens);
        uint256 tokensToReturn = rewardForBurn(numTokens);
        totalSupply = totalSupply.sub(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        poolBalance = poolBalance.sub(tokensToReturn);
        reserveToken.transfer(msg.sender, tokensToReturn, _data);

        emit Burned(numTokens, tokensToReturn);
    }

    event Minted(uint256 amount, uint256 totalCost);
    event Burned(uint256 amount, uint256 reward);
}

