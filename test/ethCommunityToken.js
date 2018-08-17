const EthCommunityToken = artifacts.require('EthCommunityToken')


contract('EthCommunityToken', (accounts) => {
  let ethCommunityToken
  const creator = accounts[0]
  const user1 = accounts[1]
  const user2 = accounts[2]

  before(async () => {
    ethCommunityToken = await EthCommunityToken.new(
      'Gluon',
      18, // what is a reasonable # of decimals?
      'GLU',
      2,
      {from: creator})
  })

  it('Is initiated correcly', async () => {
    const poolBalance = await ethCommunityToken.poolBalance.call()
    assert.equal(poolBalance, 0)
    const totalSupply = await ethCommunityToken.totalSupply.call()
    assert.equal(totalSupply, 0)
  })

  it('Is initially owned by creator', async () => {
    let owner = await ethCommunityToken.owner.call()
    assert.equal(owner, creator, 'should be owned')
  })

  it('Can mint gluons with ether', async function() {
    let balance = await ethCommunityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const priceToMint1 = await ethCommunityToken.priceToMint.call(50)
    let tx = await ethCommunityToken.mint(50, {value: priceToMint1, from: user1})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    balance = await ethCommunityToken.balanceOf(user1)
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint1)

    const priceToMint2 = await ethCommunityToken.priceToMint.call(50)
    assert.isAbove(priceToMint2.toNumber(), priceToMint1.toNumber())
    tx = await ethCommunityToken.mint(50, {value: priceToMint2, from: user2})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint2)

    const totalSupply = await ethCommunityToken.totalSupply.call()
    assert.equal(totalSupply.toNumber(), 100)

    let didThrow = false
    const priceToMint3 = await ethCommunityToken.priceToMint.call(50)
    try {
      tx = await ethCommunityToken.mint(50, {value: priceToMint3.toNumber() - 1, from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('should not be able to burn tokens user dont have', async () => {
    let didThrow = false
    try {
      tx = await ethCommunityToken.burn(80, {from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('Can burn gluons and receive ether', async () => {
    const poolBalance1 = await ethCommunityToken.poolBalance.call()
    const totalSupply1 = await ethCommunityToken.totalSupply.call()

    let reward1 = await ethCommunityToken.rewardForBurn.call(50)
    let tx = await ethCommunityToken.burn(50, {from: user1})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[0].args.reward.toNumber(), reward1)
    let balance = await ethCommunityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const poolBalance2 = await ethCommunityToken.poolBalance.call()
    assert.isBelow(poolBalance2.toNumber(), poolBalance1.toNumber())
    const totalSupply2 = await ethCommunityToken.totalSupply.call()
    assert.equal(totalSupply2.toNumber(), totalSupply1.toNumber() - 50)

    let reward2 = await ethCommunityToken.rewardForBurn.call(50)
    tx = await ethCommunityToken.burn(50, {from: user2})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[0].args.reward.toNumber(), reward2)
    balance = await ethCommunityToken.balanceOf(user2)
    assert.equal(balance.toNumber(), 0)
    assert.isBelow(reward2.toNumber(), reward1.toNumber())

    const poolBalance3 = await ethCommunityToken.poolBalance.call()
    assert.equal(poolBalance3.toNumber(), 0)
    const totalSupply3 = await ethCommunityToken.totalSupply.call()
    assert.equal(totalSupply3.toNumber(), 0)
  })
})
