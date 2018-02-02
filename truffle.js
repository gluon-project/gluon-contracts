var HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: new HDWalletProvider('', "https://rinkeby.infura.io/NziL7ta8s4ufAfVCrtgE"),
      network_id: 4
    }    
  }
};
