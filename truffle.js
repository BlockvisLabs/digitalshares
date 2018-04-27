module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",  // Match any network id
      gas: 3713094
    }
  },
  solc: {
      optimizer: {
        enabled: true,
        runs: 200
      }
  }
  // mocha: {
  //   reporter: 'eth-gas-reporter',
  //   reporterOptions : {
  //     currency: 'USD',
  //     gasPrice: 1,
  //     onlyCalledMethods: true
  //   }
  // }
};
