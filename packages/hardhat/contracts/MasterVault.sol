pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol"; 
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./BlenderTokens.sol";
import "./library/SafeMath.sol";
import "./library/UQ112xUQ112.sol";

struct basketInfo {
    address[] tokenAddresses;
    uint256[] originalTokenAmounts;
    uint256[] tokenAmounts;
    uint256 tokenExpiration;
  }

contract MasterVault {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    mapping(uint256 => basketInfo) public basketInfoMap;
    address public bptAddress;
    address public baseAddress;
    address public tknAddress;
    address public uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint256 public MAX_INT = 2**256 - 1;
    uint256 public currentId = 0;

    constructor(address _bptAddress, address _tknAddress, address _baseAddress) {
        bptAddress = _bptAddress;
        tknAddress = _tknAddress;
        baseAddress = _baseAddress;
    }

    function createBasket(address[] memory _tokens, uint256[] memory _amounts, uint256 _time) payable public returns (bool) {
        IUniswapV2Factory uniswapFactoryCast = IUniswapV2Factory(uniswapFactory);
        uint256 minTokenValue = MAX_INT;
        uint256[] memory pricePerToken = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.transferFrom(msg.sender, address(this), _amounts[i]);
            IUniswapV2Pair uniswapPairCast = IUniswapV2Pair(uniswapFactoryCast.getPair(_tokens[i], baseAddress));
            pricePerToken[i] = uint256(uniswapPairCast.price0CumulativeLast()) / 2**112;
            if (_amounts[i].mul(pricePerToken[i]) < minTokenValue) {
                minTokenValue = _amounts[i].mul(pricePerToken[i]);
            }
        }

        basketInfo memory newBasket;
        newBasket.tokenAddresses = _tokens;
        newBasket.tokenExpiration = _time;
        for (uint256 i = 0; i < _tokens.length; i++) {
            newBasket.originalTokenAmounts[i] = minTokenValue / pricePerToken[i];
            newBasket.tokenAmounts[i] = minTokenValue / pricePerToken[i];
        }
        basketInfoMap[currentId] = newBasket;

        BlenderTokens tknAddressCast = BlenderTokens(tknAddress);
        tknAddressCast.mint(msg.sender, currentId, 1000);

        BlenderTokens bptAddressCast = BlenderTokens(bptAddress);
        bptAddressCast.mint(msg.sender, currentId, 1);

        currentId += 1;
        return true;
    }

    function addToBasket(uint256 _basketId, uint256[] memory _amounts) payable public returns (bool) {
        IERC1155 tokenTkn = IERC1155(tknAddress);
        IERC1155 tokenBpt = IERC1155(bptAddress);
        require(block.timestamp < basketInfoMap[_basketId].tokenExpiration);
        uint256 tknsAwarded = MAX_INT;
        uint256 bptsAwarded = MAX_INT;
        uint256 tokenAwardRatio;
        for (uint256 i = 0; i < basketInfoMap[_basketId].tokenAddresses.length; i++) {
            IERC20 token = IERC20(basketInfoMap[_basketId].tokenAddresses[i]);
            token.transferFrom(msg.sender, address(this), _amounts[i]);
            tokenAwardRatio = (_amounts[i] / basketInfoMap[_basketId].originalTokenAmounts[i]);
            if (tokenAwardRatio * 1000 < tknsAwarded) {
                tknsAwarded = tokenAwardRatio * 1000;
            }
            if (tokenAwardRatio * 1 < bptsAwarded) {
                bptsAwarded = tokenAwardRatio * 1;
            }
        }
        for (uint256 i = 0; i < basketInfoMap[_basketId].tokenAddresses.length; i++) {
            basketInfoMap[_basketId].tokenAmounts[i] += basketInfoMap[_basketId].originalTokenAmounts[i] * tokenAwardRatio;
        }
        tokenTkn.safeTransferFrom(address(this), msg.sender, _basketId, tknsAwarded, "");
        tokenBpt.safeTransferFrom(address(this), msg.sender, _basketId, bptsAwarded, "");
        return true;
    }

    function recoverBasket(uint256 _bptId, uint256 _amount) public returns (bool) { // only BPT
        require(block.timestamp >= basketInfoMap[_bptId].tokenExpiration);
        IERC1155 tokenBpt = IERC1155(bptAddress);
        tokenBpt.safeTransferFrom(msg.sender, address(this), _bptId, _amount, "");
        for (uint256 i = 0; i < basketInfoMap[_bptId].tokenAddresses.length; i++) {
            BlenderTokens bptAddressCast = BlenderTokens(bptAddress);
            IERC20 tokenAddresses1 = IERC20(basketInfoMap[_bptId].tokenAddresses[i]);
            tokenAddresses1.transferFrom(address(this), msg.sender, ( (basketInfoMap[_bptId].tokenAmounts[i] / bptAddressCast.totalSupply(_bptId)) * _amount));
            basketInfoMap[_bptId].tokenAmounts[i] -= ( (basketInfoMap[_bptId].tokenAmounts[i] / bptAddressCast.totalSupply(_bptId)) * _amount);
        }
        return true;
    }

    function redeemTkn(uint256 _tknId, uint256 _amount, address _newTokenAddress) public returns (bool) { // only TKN
        require(block.timestamp < basketInfoMap[_tknId].tokenExpiration);
        IERC1155 tokenTkn = IERC1155(tknAddress);
        tokenTkn.safeTransferFrom(msg.sender, address(this), _tknId, _amount, "");
        for (uint256 i = 0; i < basketInfoMap[_tknId].tokenAddresses.length; i++) {
            if (basketInfoMap[_tknId].tokenAddresses[i] == _newTokenAddress) {
                BlenderTokens tknAddressCast = BlenderTokens(tknAddress);
                IERC20 _newTokenAddressCast = IERC20(_newTokenAddress);
                _newTokenAddressCast.transferFrom(address(this), msg.sender, ( (basketInfoMap[_tknId].tokenAmounts[i] / tknAddressCast.totalSupply(_tknId)) * _amount));
                basketInfoMap[_tknId].tokenAmounts[i] -= ( (basketInfoMap[_tknId].tokenAmounts[i] / tknAddressCast.totalSupply(_tknId)) * _amount);
            }
        }
        return true;
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}
}