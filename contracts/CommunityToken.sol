pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
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
contract GluonToken is ERC223Token, BancorFormula, Ownable {
    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance = 0;

    /*
     * @dev reserve ratio, represented in ppm, 1-1000000
     * 1/3 corresponds to y= multiple * x^2
     * 1/2 corresponds to y= multiple * x
     * 2/3 corresponds to y= multiple * x^1/2
     * multiple will depends on contract initialization,
     * specificallytotalAmount and poolBalance parameters
     * we might want to add an 'initialize' function that will allow
     * the owner to send ether to the contract and mint a given amount of tokens
     */
    uint32 public reserveRatio;

    /**
     * @dev the token used for reserve
     */
    ERC223Token public reserveToken;

    /*
     * - Front-running attacks are currently mitigated by the following mechanisms:
     * TODO - minimum return argument for each conversion provides a way to define a minimum/maximum price for the transaction
     * - gas price limit prevents users from having control over the order of execution
     */
    uint256 public gasPrice = 0 wei; // maximum gas price for bancor transactions

    function BondingCurve(
        uint32 _reserveRatio,
        address _reserveToken,
        uint256 _gasPrice,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        reserveRatio = _reserveRatio;
        reserveToken = ERC223Token(_reserveToken);
        totalSupply = _totalSupply;
        gasPrice = _gasPrice;

        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(_from == address(reserveToken));
        require(buy(_value));
    }

    /**
     * @dev Buy tokens
     * gas ~ 77825
     * TODO implement maxAmount that helps prevent miner front-running
     */
    function buy(address _from, uint256 _value) validGasPrice internal returns(bool) {
        require(_value > 0);
        uint256 tokensToMint = calculatePurchaseReturn(totalSupply, poolBalance, reserveRatio, _value);
        totalSupply = totalSupply.add(tokensToMint);
        balances[_from] = balances[_from].add(tokensToMint);
        poolBalance = poolBalance.add(_value);
        LogMint(tokensToMint, _value);
        return true;
    }

    /**
     * @dev Sell tokens
     * gas ~ 86936
     * @param sellAmount Amount of tokens to withdraw
     * TODO implement maxAmount that helps prevent miner front-running
     */
    function sell(uint256 sellAmount, bytes _data) validGasPrice public returns(bool) {
        require(sellAmount > 0 && balances[msg.sender] >= sellAmount);
        uint256 reserveTokenAmount = calculateSaleReturn(totalSupply, poolBalance, reserveRatio, sellAmount);
        reserveToken.transfer(msg.sender, reserveTokenAmount, _data);
        poolBalance = poolBalance.sub(ethAmount);
        balances[msg.sender] = balances[msg.sender].sub(sellAmount);
        totalSupply = totalSupply.sub(sellAmount);
        LogWithdraw(sellAmount, ethAmount);
        return true;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        assert(tx.gasprice <= gasPrice);
        _;
    }

    /**
     * @dev Allows the owner to update the gas price limit
     * @param _gasPrice The new gas price limit
     */
    function setGasPrice(uint256 _gasPrice) onlyOwner public {
        require(_gasPrice > 0);
        gasPrice = _gasPrice;
    }

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogWithdraw(uint256 amountWithdrawn, uint256 reward);
    event LogBondingCurve(string logString, uint256 value);
}
