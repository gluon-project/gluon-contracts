import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";


contract ERC20Token is StandardToken {

    string public name;
    uint8 public decimals;
    string public symbol;

    function ERC20Token(
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint256 _totalSupply
    ) public {
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }
}

