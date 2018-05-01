const GluonToken = artifacts.require('GluonToken')
const CommunityToken = artifacts.require('CommunityToken')


const uintToBytes = uint => {
  const hexInt = uint.toString(16)
  return '0x' + '0'.repeat(64 - hexInt.length) + hexInt
}

contract('CommunityToken', (accounts) => {
  let gluonToken
  let communityToken
  const creator = accounts[0]
  const user1 = accounts[1]
  const user2 = accounts[2]

  before(async () => {
    gluonToken = await GluonToken.new(
      'Gluon',
      18, // what is a reasonable # of decimals?
      'GLU',
      2,
      {from: creator})
    communityToken = await CommunityToken.new(
      'TestToken',
      18, // what is a reasonable # of decimals?
      'TTK',
      2,
      gluonToken.address,
      {from: creator})
    let numTokens = 500000
    let priceToMint = await gluonToken.priceToMint.call(numTokens)
    await gluonToken.mint(numTokens, {value: priceToMint, from: user1})
    priceToMint = await gluonToken.priceToMint.call(numTokens)
    await gluonToken.mint(numTokens, {value: priceToMint, from: user2})
  })

  it('Is initiated correcly', async () => {
    const poolBalance = await communityToken.poolBalance.call()
    assert.equal(poolBalance, 0)
    const totalSupply = await communityToken.totalSupply.call()
    assert.equal(totalSupply, 0)
    const exponent = (await communityToken.exponent.call()).toNumber()
    assert.equal(exponent, 2)
    const reserveToken = await communityToken.reserveToken.call()
    assert.equal(reserveToken, gluonToken.address)
  })

  it('Is initially owned by creator', async () => {
    let owner = await communityToken.owner.call()
    assert.equal(owner, creator, 'should be owned')
  })

  it('Can mint tokens with gluons', async function() {
    let balance = await communityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const priceToMint1 = await communityToken.priceToMint.call(50)
    const numTokensBytes = uintToBytes(50)
    let tx = await gluonToken.transfer(communityToken.address, priceToMint1, numTokensBytes, {from: user1})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint1)
    balance = await communityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 50)

    balance = await communityToken.balanceOf(user2)
    assert.equal(balance.toNumber(), 0)
    const priceToMint2 = await communityToken.priceToMint.call(50)
    assert.isAbove(priceToMint2.toNumber(), priceToMint1)
    tx = await gluonToken.transfer(communityToken.address, priceToMint2, numTokensBytes, {from: user2})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint2)
    balance = await communityToken.balanceOf(user2)
    assert.equal(balance.toNumber(), 50)

    const totalSupply = await communityToken.totalSupply.call()
    assert.equal(totalSupply.toNumber(), 100)
  })

  it('cant mint if to little gluons sent', async () => {
    let didThrow = false
    const priceToMint3 = await communityToken.priceToMint.call(50)
    try {
      await gluonToken.transfer(communityToken.address, priceToMint3.toNumber() - 1, numTokensBytes, {from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('should not be able to burn tokens user dont have', async () => {
    let balance = await communityToken.balanceOf(user2)
    let didThrow = false
    try {
      tx = await communityToken.burn(80, '0x0', {from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('Can burn gluons and receive ether', async () => {
    const poolBalance1 = await communityToken.poolBalance.call()
    const totalSupply1 = await communityToken.totalSupply.call()

    let reward1 = await communityToken.rewardForBurn.call(50)
    let tx = await communityToken.burn(50, '0x0', {from: user1})
    assert.equal(tx.logs[1].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[1].args.reward.toNumber(), reward1)
    let balance = await communityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const poolBalance2 = await communityToken.poolBalance.call()
    assert.isBelow(poolBalance2.toNumber(), poolBalance1.toNumber())
    const totalSupply2 = await communityToken.totalSupply.call()
    assert.equal(totalSupply2.toNumber(), totalSupply1.toNumber() - 50)

    let reward2 = await communityToken.rewardForBurn.call(50)
    tx = await communityToken.burn(50, '0x0', {from: user2})
    assert.equal(tx.logs[1].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[1].args.reward.toNumber(), reward2)
    balance = await communityToken.balanceOf(user2)
    assert.equal(balance.toNumber(), 0)
    assert.isBelow(reward2.toNumber(), reward1.toNumber())

    const poolBalance3 = await communityToken.poolBalance.call()
    assert.equal(poolBalance3.toNumber(), 0)
    const totalSupply3 = await communityToken.totalSupply.call()
    assert.equal(totalSupply3.toNumber(), 0)
  })
})
