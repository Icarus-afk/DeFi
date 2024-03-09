module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1", // Replace with Ganache host if different
      port: 7545,
      network_id: 5777, // Ganache default network ID
      gas: 5000, // Gas limit for deployment (adjust as needed)
      gasPrice: 20000000000, // Gas price (adjust as needed)
      accounts: [
        "0xa800662caafd43f843cf55c3e44be312a73a5a3748b5a765fb5f3a78fc867a05" // Replace with Ganache account private key
      ]
    }
  },
  compilers: {
    solc: {
      version: '0.8.20',
      settings: {
        optimizer: {
          enabled: false, // Default: false
          runs: 200      // Default: 200
        },
      }
    }
  }
};
