// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDT} from "../lib/USDT.sol";
import "forge-std/console.sol";

/// @title A Logarithm Games project BSC network token
/// @author Logarithm Games
/// @notice
contract LOGG is ERC20, Ownable {

    event Minted(address, uint);
    event Bought(address, uint);
    event Burned(address, uint);

    bool private _saleStatus;
    uint256 private _priceUSDT = 5000000000000000 wei;// 0,005 USDT
    uint256 private _bnbPrice = 20000000000000 wei; //0,00002 BNB
    uint256 private _totalSaleAmount;
    address public underlyingToken = 0x55d398326f99059fF775485246999027B3197955; //USDT BSC Network (Can be set)
    uint256 private constant MAX_TOTAL_SUPPLY = 1_000_000_000e18;

    error SaleNotActive();
    error ToLowAmount();
    error IncorrectAmount();
    error IncorrectAddress();
    error ExceededTotalSaleAmount();
    error IncorrectPrice();
    error NothingToWithdraw();
    error IncorrectValue();
    error NotEnoughAllowance();

    constructor(uint256 totalAmount, address _owner) ERC20("Logarithm Games Token", "LOGG") Ownable(_owner){
        _totalSaleAmount = totalAmount;
    }

    //////////////////////  USER'S FUNCTIONS  ///////////////////////

    /// @notice This function is for public sale USDT-buyers
    /// @param amountUSDT Amount is amount of USDT(BSC) that buyer supposes to spend
    /// @notice amountUSDT must be 18-digit
    /// @return Return the bought amount of LOGG tokens
    function buyForUSDT(uint256 amountUSDT) external returns(uint256){
        if (!_saleStatus) revert SaleNotActive();
        if (amountUSDT == 0) revert IncorrectAmount();
        uint256 loggAmount = amountUSDT * 1 ether / _priceUSDT;

        if ((loggAmount + totalSupply()) > MAX_TOTAL_SUPPLY) revert IncorrectAmount();
        if (loggAmount > _totalSaleAmount) revert ExceededTotalSaleAmount();

        _totalSaleAmount -= loggAmount;
        if (IERC20(underlyingToken).allowance(msg.sender, address(this)) < amountUSDT) revert NotEnoughAllowance();
        IERC20(underlyingToken).transferFrom(msg.sender, address(this), amountUSDT);
        _mint(_msgSender(), loggAmount);
        emit Bought(_msgSender(), loggAmount);
        return loggAmount;
    }

    /// @notice This function is for public sale BNB-buyers
    /// @return Return the bought amount of LOGG tokens
    function buyForBNB() external payable returns(uint256){
        if (!_saleStatus) revert SaleNotActive();
        if (msg.value == 0) revert IncorrectValue();
        uint256 loggAmount = msg.value * 1 ether / _bnbPrice;

        if ((loggAmount + totalSupply()) > MAX_TOTAL_SUPPLY) revert IncorrectAmount();
        if (loggAmount > _totalSaleAmount) revert ExceededTotalSaleAmount();

        _totalSaleAmount -= loggAmount;
        _mint(_msgSender(), loggAmount);
        emit Bought(_msgSender(), loggAmount);
        return loggAmount;
    }

    //////////////////////  GETTERS  ///////////////////////

    /// @dev In BSC chain the USDT token has 18 digits so we have to use 18 digits with LOGG token
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function getUSDTPrice() external view returns (uint256){
        return _priceUSDT;
    }

    function getBNBPrice() external view returns (uint256) {
        return _bnbPrice;
    }

    function getSaleTotalAmount() external view returns (uint256){
        return _totalSaleAmount;
    }

    function getSaleStatus() external view returns (bool){
        return _saleStatus;
    }

    function getExactUSDTAmount(uint256 loggWanted) external view returns (uint256 exactUSDT){
        if(_priceUSDT == 0) revert IncorrectPrice();
        exactUSDT = loggWanted * _priceUSDT / 1 ether;
    }

    function getExactBNBAmount(uint256 loggWanted) external view returns (uint256 exactBNB) {
        if(_priceUSDT == 0) revert IncorrectPrice();
        exactBNB = loggWanted * _bnbPrice / 1 ether;
    }

    ////////////////////// OWNER'S FUNCTIONS ///////////////////////

    /// @notice This function is for minting tokens
    /// @param amount Amount of tokens to mint
    function mint(uint256 amount, address to) external onlyOwner {
        if (amount == 0) revert IncorrectAmount();
        if ((amount + totalSupply()) < totalSupply()) revert IncorrectAmount();
        if ((amount + totalSupply()) > MAX_TOTAL_SUPPLY) revert IncorrectAmount();
        if (to == address(this)) revert IncorrectAddress();

        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(uint256 amount, address from) external onlyOwner {
        if (amount == 0) revert IncorrectAmount();
        if (from == address(this)) revert IncorrectAddress();

        _burn(from, amount);
        emit Burned(from, amount);
    }

    function setUSDTPrice(uint256 price) external onlyOwner {
        if(price == 0) revert IncorrectPrice();
        _priceUSDT = price;
    }

    function setBNBPrice(uint256 price) external onlyOwner {
        if(price == 0) revert IncorrectPrice();
        _bnbPrice = price;
    }

    function setSaleTotalAmount(uint256 amount) external onlyOwner {
        if(amount == 0) revert IncorrectAmount();
        _totalSaleAmount = amount;
    }

    /// @notice This function close or open public sale
    /// @param newSaleStatus If this param is true sale is opened and otherwise sale is closed
    function setSaleStatus(bool newSaleStatus) external onlyOwner {
        _saleStatus = newSaleStatus;
    }

    function setToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Zero address!");
        underlyingToken = newToken;
    }

    /// @notice Since this token is a fundrising token all value will be received by team
    function withdrawAll() external onlyOwner {
        uint256 amountToWithdraw = IERC20(underlyingToken).balanceOf(address(this));
        uint256 bnbAmount2withdraw = address(this).balance;
        if(amountToWithdraw == 0 && bnbAmount2withdraw == 0) revert NothingToWithdraw();
        if(amountToWithdraw > 0){
            IERC20(underlyingToken).transfer(owner(),  amountToWithdraw);
        }
        if(bnbAmount2withdraw > 0){
            payable(owner()).transfer(bnbAmount2withdraw);
        }
    }

    function withdrawUSDT(uint256 amount) external onlyOwner {
        uint256 balance = IERC20(underlyingToken).balanceOf(address(this));
        if(balance < amount) revert NothingToWithdraw();
        IERC20(underlyingToken).transfer(owner(), amount);
    }

    function withdrawBNB(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance < amount) revert NothingToWithdraw();
        payable(owner()).transfer(amount);
    }
}