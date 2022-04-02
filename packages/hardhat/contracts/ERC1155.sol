pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155BPT is ERC1155, Ownable {

    constructor() ERC1155("") {
        
    } 

    function mint(address recipient, uint256 id, uint256 amount) onlyOwner public {
        _mint(recipient, id, amount, "");
    }
}