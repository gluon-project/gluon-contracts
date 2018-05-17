const coder = require('web3/lib/solidity/coder');

const uintToBytes = uint => {
  const hexInt = uint.toString(16)
  return '0x' + '0'.repeat(64 - hexInt.length) + hexInt
}

const facotryDataTypes = ['string', 'uint8', 'string', 'uint8']
const encodeFactoryData = (numTokens, name, decimals, symbol, exponent) =>
  uintToBytes(numTokens) + coder.encodeParams(facotryDataTypes, [name, decimals, symbol, exponent])

const priceToMintFirst = (numTokens, exponent) => {
  const one = 10000000000
  exponent++
  return Math.floor((Math.floor(one / exponent) * numTokens**exponent) / one)
}

module.exports = {
  uintToBytes,
  encodeFactoryData,
  priceToMintFirst
}
