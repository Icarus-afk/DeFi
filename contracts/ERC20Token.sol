// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    address public minter;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(bytes(_name).length > 0, "Name cannot be empty");
        minter = msg.sender;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "Only minter can mint tokens");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
