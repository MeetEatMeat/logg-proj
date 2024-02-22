// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBEP20} from "./IBEP.sol";

/// @title A Logarithm Games project BSC network token
/// @author
/// @notice
contract LOGG is ERC20, Ownable {

    event Minted(address, uint);
    event Bought(address, uint);
    event Burned(address, uint);

    bool private _saleStatus;
    uint256 private _priceUSDT = 5000000000000000 wei;// 0,005 USDT
    uint256 private _bnbPrice = 20000000000000 wei; //0,00002 BNB
    uint256 private _totalSaleAmount;
    address public underlyingToken = 0x55d398326f99059fF775485246999027B3197955; //USDT BSC Network
    uint256 private constant MAX_TOTAL_SUPPLY = 1_000_000_000e18;

    mapping(address => uint256) public leftovers;

    error SaleNotActive();
    error ToLowAmount();
    error IncorrectAmount();
    error IncorrectAddress();
    error ExceededTotalSaleAmount();
    error IncorrectPrice();
    error NothingToWithdraw();

    constructor(uint256 totalAmount, address owner) ERC20("Logarithm Games Token", "LOGG") Ownable(owner){
        _totalSaleAmount = totalAmount;
    }

    //////////////////////  USER'S FUNCTIONS  ///////////////////////

    /// @notice This function is for public sale buyers
    /// @param amount Amount is amount of USDT(BSC) that buyer supposes to spend
    /// @return Return the bought amount of LOGG tokens
    function buy(uint256 amount) external payable returns(uint256){
        if (!_saleStatus) revert SaleNotActive();
        if ((amount + totalSupply()) > MAX_TOTAL_SUPPLY) revert IncorrectAmount();
        if (amount > _totalSaleAmount) revert ExceededTotalSaleAmount();
        if (amount < 200e18) revert IncorrectAmount();// 200 LOGG are equal to $1

        return _buy(amount);
    }

    function withdrawLeftovers() external {
        uint256 leftover = leftovers[msg.sender];
        if(leftover == 0) revert NothingToWithdraw();
        leftovers[msg.sender] = 0;
        payable(msg.sender).transfer(leftover);
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
        exactUSDT = loggWanted * _priceUSDT;
    }

    function getExactBNBAmount(uint256 loggWanted) external view returns (uint256 exactBNB) {
        if(_priceUSDT == 0) revert IncorrectPrice();
        exactBNB = loggWanted * _bnbPrice;
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
        uint256 amountToWithdraw = IBEP20(underlyingToken).balanceOf(address(this));
        uint256 bnbAmount2withdraw = address(this).balance;
        if(amountToWithdraw == 0 && bnbAmount2withdraw == 0) revert NothingToWithdraw();
        if(amountToWithdraw > 0){
            IBEP20(underlyingToken).transfer(owner(),  amountToWithdraw);
        }
        if(bnbAmount2withdraw > 0){
            payable(owner()).transfer(bnbAmount2withdraw);
        }
    }

    function withdrawUSDT(uint256 amount) external onlyOwner {
        uint256 balance = IBEP20(underlyingToken).balanceOf(address(this));
        if(balance < amount) revert NothingToWithdraw();
        IBEP20(underlyingToken).transfer(owner(), amount);
    }

    function withdrawBNB(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance < amount) revert NothingToWithdraw();
        payable(owner()).transfer(amount);
    }

    ////////////////////// INTERNAL FUNCTIONS ///////////////////////

    function _buy(uint256 amount) internal returns(uint256){
        uint256 loggAmount = amount;
        if(_priceUSDT == 0 || _bnbPrice == 0) revert IncorrectPrice();
        if(msg.value > 0){
            uint256 bnbAmount = loggAmount * _bnbPrice;
            if(msg.value < bnbAmount) revert ToLowAmount();
            _totalSaleAmount -= loggAmount;
            _mint(_msgSender(), loggAmount);
            emit Bought(_msgSender(), loggAmount);

            if(msg.value > bnbAmount){
                uint256 leftover = msg.value - bnbAmount;
                leftovers[msg.sender] += leftover;
            }
            return loggAmount;
        }

        uint256 usdtAmount = loggAmount * _priceUSDT;

        uint256 prevBalance = IBEP20(underlyingToken).balanceOf(address(this));
        IBEP20(underlyingToken).transferFrom(msg.sender, address(this), usdtAmount);
        uint256 newBalance = IBEP20(underlyingToken).balanceOf(address(this));

        if(!(newBalance > prevBalance)) revert ToLowAmount();
        uint256 exactUsdtSpent = newBalance - prevBalance;
        
        if (exactUsdtSpent < usdtAmount){
            uint256 exactLoggAmount = exactUsdtSpent / _priceUSDT;
            _totalSaleAmount -= exactLoggAmount;
            _mint(_msgSender(), exactLoggAmount);
            
            emit Bought(_msgSender(), exactLoggAmount);
            return exactLoggAmount;
        }

        _totalSaleAmount -= loggAmount;
        _mint(_msgSender(), loggAmount);

        emit Bought(_msgSender(), loggAmount);
        return loggAmount;
    }
}