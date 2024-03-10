import Web3 from 'web3';
import ERC20TokenABI from './ERC20Token.json' assert { type: 'json' }; // Import ERC20 token ABI

const web3 = new Web3('http://localhost:7545'); // Initialize Web3 with Ganache URL

const abi = ERC20TokenABI.abi; // Access the ABI from the imported JSON object

const tokenAddress = '0x85F27f127b286a78fDdA151eFCf48326A9fE5B7c'; // Replace with your deployed ERC20 token address
const tokenContract = new web3.eth.Contract(abi, tokenAddress); // Pass the ABI to the Contract constructor

const minterAddress = '0x5E26386CEb966B81706B3bC53fA55C932056a174'; // Address of the minter
const recipientAddress = '0x5E26386CEb966B81706B3bC53fA55C932056a174'; // Address to receive the minted tokens
const amountToMint = 1000; // Amount of tokens to mint

console.log(ERC20TokenABI);

// Call mint function to mint tokens
tokenContract.methods.mint(recipientAddress, amountToMint)
    .send({ from: minterAddress })
    .then((receipt) => {
        console.log('Tokens minted successfully:', receipt);
    })
    .catch((error) => {
        console.error('Error minting tokens:', error);
    });
