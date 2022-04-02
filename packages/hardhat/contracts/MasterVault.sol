pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

contract MasterVault {

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}