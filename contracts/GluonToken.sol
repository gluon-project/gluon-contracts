pragma solidity ^0.4.18;

import "zeppelin/contracts/ownership/Ownable.sol";
import "./ERC223_Token.sol";
import "./Receiver_Interface.sol";
import "./BancorFormula.sol";


/**
 * @title Gluon Token
 * @dev Bonding curve contract based on Bacor formula
 * inspired by bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 */
contract GluonToken is ERC223Token, Ownable {
    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance = 0;

    uint8 public exponent;

    /*
     * - Front-running attacks are currently mitigated by the following mechanisms:
     * TODO - minimum return argument for each conversion provides a way to define a minimum/maximum price for the transaction
     * - gas price limit prevents users from having control over the order of execution
     */
    uint256 public gasPrice; // maximum gas price for bancor transactions

    function GluonToken(
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

    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        totalSupply = totalSupply.add(numTokens);
        balances[msg.sender] = balances[msg.sender].add(numTokens);
        poolBalance = poolBalance.add(msg.value);
        // TODO - send back any additional ether
        emit LogMint(numTokens, msg.value);
    }

    function priceToMint(uint256 numTokens) public returns(uint256) {
        return curveIntegral(totalSupply + numTokens) - poolBalance;
    }

    function rewardForBurn(uint256 numTokens) public returns(uint256) {
        return poolBalance - curveIntegral(totalSupply - numTokens);
    }

    function burn(uint256 numTokens) public returns(bool) {
        require(balances[msg.sender] >= numTokens);
        uint256 ethToReturn = rewardForBurn(numTokens);
        totalSupply = totalSupply.sub(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        poolBalance = poolBalance.sub(ethToReturn);
        msg.sender.transfer(ethToReturn);

        emit LogBurn(numTokens, ethToReturn);
    }

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogBurn(uint256 amountBurned, uint256 reward);
}
