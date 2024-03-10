module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 6721975,
      gasPrice: 20000000000,
      accounts: ["0x62edf306d0ca7a729f885e47133c459908d2309183cb2abf4677d187d9e86c5b"]
    },
    loc_defi_defi: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      gas: 6721975,
      gasPrice: 20000000000,
      accounts: ["0xf84e2bee97b8529b780af0837a53eb6e370eb71223ead09a440dccf99655df6f"]
    }
  },
  compilers: {
    solc: {
      version: '0.8.13',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
