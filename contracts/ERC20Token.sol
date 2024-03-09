pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(uint256 totalSupply) ERC20("MyToken", "MTK") Ownable() {
        _mint(msg.sender, totalSupply);
    }

    // Function to mint new tokens
    function mint(address recipient, uint256 amount) public onlyOwner {
        _mint(recipient, amount);
    }

    // Function to burn tokens
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}