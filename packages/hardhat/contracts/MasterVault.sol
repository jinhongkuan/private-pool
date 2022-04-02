pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; 

struct basketInfo {
    address[] tokenAddresses;
    uint256[] tknRatio;
    uint256[] bptRatio;
    uint256[] tokenAmounts;
    uint256 tokenExpiration;
  }

contract MasterVault {
    mapping(uint256 => basketInfo) basketInfoMap;
    address bptAddress;
    address tknAddress;
    address baseAddress; 

    constructor(address _bptAddress, address _tknAddress, address _baseAddress) {
        bptAddress = _bptAddress;
        tknAddress = _tknAddress;
        baseAddress = _baseAddress;
    }

    function createBasket(address[] _tokens, uint256[] _amounts) payable {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(_tokens[i].transferFrom(msg.sender, this, _amounts[i]));
        }

    }

    function addToBasket() payable {

    }

    function recoverBasket(uint256 _bptId, uint256 _amount) returns (bool) { // only BPT
        require(block.timestamp >= basketInfoMap[_bptId].tokenExpiration);
        require(bptAddress.safeTransferFrom(msg.sender, this, _bptId, _amount, ""));
        for (uint256 i = 0; i < basketInfoMap[_bptId].tokenAddresses; i++) {
            basketInfoMap[_bptId].tokenAddresses[i].transferFrom(this, msg.sender, (basketInfoMap[_bptId].bptRatio[i] * _amount));
        }
    }

    function redeemTkn(uint256 _tknId, uint256 _amount) { // only TKN
        require(block.timestamp < basketInfoMap[_tknId].tokenExpiration);
        require(tknAddress.safeTransferFrom(msg.sender, this, _tknId, _amount, ""));
        for (uint256 i = 0; i < basketInfoMap[_tknId].tokenAddresses; i++) {
            basketInfoMap[_tknId].tokenAddresses[i].transferFrom(this, msg.sender, (basketInfoMap[_tknId].tknRatio[i] * _amount));
        }
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}
}