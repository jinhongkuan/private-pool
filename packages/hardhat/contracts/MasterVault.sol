pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; 

struct basketInfo {
    address[] tokenAddresses;
    uint256[] originalTokenAmounts;
    uint256[] tokenAmounts;
    uint256 tokenExpiration;
  }

contract MasterVault {
    mapping(uint256 => basketInfo) public basketInfoMap;
    address public bptAddress;
    address public baseAddress;
    address public tknAddress;
    uint256 public MAX_INT = 2**256 - 1;

    constructor(address _bptAddress, address _tknAddress, address _baseAddress) {
        bptAddress = _bptAddress;
        tknAddress = _tknAddress;
        baseAddress = _baseAddress;
    }

    function createBasket(address[] _tokens, uint256[] _amounts) payable public returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].transferFrom(msg.sender, this, _amounts[i]);
        }

        return true;
    }

    function addToBasket(uint256 _basketId, uint256[] _amounts) payable public returns (bool) {
        require(block.timestamp < basketInfoMap[_basketId].tokenExpiration);
        uint256 tknsAwarded = MAX_INT;
        uint256 bptsAwarded = MAX_INT;
        for (uint256 i = 0; i < basketInfoMap[_basketId].tokenAddresses.length; i++) {
            basketInfoMap[_basketId].tokenAddresses[i].transferFrom(msg.sender, this, _amounts[i]);
            basketInfoMap[_basketId].tokenAmounts[i] -= _amounts[i];
            uint256 tokenAwardRatio = (_amounts[i] / basketInfoMap[_basketId].originalTokenAmounts[i]);
            if (tokenAwardRatio * 1000 < tknsAwarded) {
                tknsAwarded = tokenAwardRatio * 1000;
            }
            if (tokenRatio * 1 < bptsAwarded) {
                bptsAwarded = tokenAwardRatio * 1;
            }
        }
        tknAddress.safeTransferFrom(this, msg.sender, tknsAwarded, "");
        bptAddress.safeTransferFrom(this, msg.sender, bptsAwarded, "");
        return true;
    }

    function recoverBasket(uint256 _bptId, uint256 _amount) public returns (bool) { // only BPT
        require(block.timestamp >= basketInfoMap[_bptId].tokenExpiration);
        bptAddress.safeTransferFrom(msg.sender, this, _bptId, _amount, "");
        for (uint256 i = 0; i < basketInfoMap[_bptId].tokenAddresses; i++) {
            basketInfoMap[_bptId].tokenAddresses[i].transferFrom(this, msg.sender, ( (basketInfoMap[_bptId].tokenAmounts[i] / bptAddress.supply[_bptId]) * _amount));
            basketInfoMap[_basketId].tokenAmounts[i] -= ( (basketInfoMap[_bptId].tokenAmounts[i] / bptAddress.supply[_bptId]) * _amount);
        }
        return true;
    }

    function redeemTkn(uint256 _tknId, uint256 _amount, address _newTokenAddress) public returns (bool) { // only TKN
        require(block.timestamp < basketInfoMap[_tknId].tokenExpiration);
        tknAddress.safeTransferFrom(msg.sender, this, _tknId, _amount, "");
        _newTokenAddress.transferFrom(this, msg.sender, ( (basketInfoMap[_tknId].tokenAmounts[i] / tknAddress.totalSupply[_tknID]) * _amount));
        basketInfoMap[_basketId].tokenAmounts[i] -= ( (basketInfoMap[_tknId].tokenAmounts[i] / tknAddress.totalSupply[_tknID]) * _amount);
        return true;
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}
}