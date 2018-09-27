const EthCommunityToken = artifacts.require('EthCommunityToken')
const CommunityToken = artifacts.require('CommunityToken')
const CommunityTokenFactory = artifacts.require('CommunityTokenFactory')

const glutils = require('../utils/glutils.js')


contract('CommunityTokenFactory', (accounts) => {
  let gluonToken
  let communityTokenFactory
  const creator = accounts[0]
  const user1 = accounts[1]
  const user2 = accounts[2]

  before(async () => {
    gluonToken = await EthCommunityToken.new(
      'Gluon',
      18, // what is a reasonable # of decimals?
      'GLU',
      2,
      {from: creator})
    communityTokenFactory = await CommunityTokenFactory.new(gluonToken.address)
    const numTokens = 500000
    const priceToMint = await gluonToken.priceToMint.call(numTokens)
    await gluonToken.mint(numTokens, {value: priceToMint, from: user1})
  })

  it('Is initiated correcly', async () => {
    const gluonAddress = await communityTokenFactory.gluon.call()
    assert.equal(gluonAddress, gluonToken.address)
    const numCreatedTokens = await communityTokenFactory.getNumberOfCreatedTokens.call()
    assert.equal(numCreatedTokens.toNumber(), 0, 'no tokens should be created yet')
  })

  it('creates gluonbacked community token', async () => {
    const numTokensToMint = 20
    const priceForTokens = glutils.priceToMintFirst(numTokensToMint, 2)
    const creationData = glutils.encodeFactoryData(numTokensToMint, 'myToken', 18, 'MTK', 2)

    let tx = await gluonToken.transfer(communityTokenFactory.address, priceForTokens, creationData, {from: user1})
    const numCreatedTokens = await communityTokenFactory.getNumberOfCreatedTokens.call()
    const newTokenAddr = await communityTokenFactory.createdTokens.call(numCreatedTokens - 1)
    const token = CommunityToken.at(newTokenAddr)

    const u1Balance = await token.balanceOf(user1)
    assert.equal(u1Balance.toNumber(), 20)
    const u1GluBalance = await gluonToken.balanceOf(user1)
    assert.equal(u1GluBalance.toNumber(), 500000 - priceForTokens)
    const tokenGluBalance = await gluonToken.balanceOf(newTokenAddr)
    assert.equal(tokenGluBalance.toNumber(), priceForTokens)

    const tokenName = await token.name.call()
    assert.equal(tokenName, 'myToken')
    const exponent = await token.exponent.call()
    assert.equal(exponent.toNumber(), 2)
  })

  it('creates a eth backed community token', async () => {
    const numTokensToMint = 20
    const priceForTokens = glutils.priceToMintFirst(numTokensToMint, 2)

    const tx = await communityTokenFactory.createEthCommunityTokenAndMint('myToken', 18, 'MTK', 2, numTokensToMint, {value: priceForTokens, from: user1})
    const token = EthCommunityToken.at(tx.logs[0].args.addr)

    const u1Balance = await token.balanceOf(user1)
    assert.equal(u1Balance.toNumber(), 20)

    const tokenName = await token.name.call()
    assert.equal(tokenName, 'myToken')
    const exponent = await token.exponent.call()
    assert.equal(exponent.toNumber(), 2)
  })

  it('creates an erc20 token', async () => {
    const totalSupply = 1000

    const tx = await communityTokenFactory.createERC20Token('myToken', 18, 'MTK', totalSupply, {from: user1})
    const token = EthCommunityToken.at(tx.logs[0].args.addr)

    const u1Balance = await token.balanceOf(user1)
    assert.equal(u1Balance.toNumber(), totalSupply)

    const tokenName = await token.name.call()
    assert.equal(tokenName, 'myToken')
    const supply = await token.totalSupply.call()
    assert.equal(supply.toNumber(), totalSupply)
  })
})
