// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBEP20} from "./IBEP.sol";

/// @title A Logarithm Games project BSC network token

contract LOGG is ERC20, Ownable {

    event Minted(address, uint);
    event Bought(address, uint);
    event Burned(address, uint);

    bool private _saleStatus;
    uint256 private _price = 5000000000000000 wei;// 0,005 USDT
    uint256 private _totalSaleAmount;
    address public constant _USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 private constant MAX_TOTAL_SUPPLY = 1_000_000_000e18;

    error SaleNotActive();
    error ToLowAmount();
    error IncorrectAmount();
    error IncorrectAddress();
    error ExceededTotalSaleAmount();
    error IncorrectPrice();

    constructor(uint256 totalAmount, address owner) ERC20("Logarithm Games Token", "LOGG") Ownable(owner){
        _totalSaleAmount = totalAmount;
    }

    //////////////////////  USER'S FUNCTIONS  ///////////////////////

    /// @notice This function is for public sale buyers
    /// @param amount Amount is amount of USDT(BSC) that buyer supposes to spend
    /// @return Return the bought amount of LOGG tokens
    function buy(uint256 amount) external returns(uint256){
        if (!_saleStatus) revert SaleNotActive();
        if ((amount + totalSupply()) > MAX_TOTAL_SUPPLY) revert IncorrectAmount();
        if (amount > _totalSaleAmount) revert ExceededTotalSaleAmount();
        if (amount == 0) revert IncorrectAmount();

        return _buy(amount);
    }

    //////////////////////  GETTERS  ///////////////////////

    /// @dev In BSC chain the USDT token has 18 digits so we have to use 18 digits with LOGGI token
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function getPrice() external view returns (uint256){
        return _price;
    }

    function getSaleTotalAmount() external view returns (uint256){
        return _totalSaleAmount;
    }

    function getSaleStatus() external view returns (bool){
        return _saleStatus;
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

    function setPrice(uint256 price) external onlyOwner {
        if(price == 0) revert IncorrectPrice();
        _price = price;
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

    /// @notice Since this token is a fundrising token all value will be received by team
    function withdrawAll() external onlyOwner {
        uint256 amountToWithdraw = IBEP20(_USDT).balanceOf(address(this));
        require(amountToWithdraw > 0, "Nothing to withdraw");
        IBEP20(_USDT).transfer(owner(),  amountToWithdraw);
    }

    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = IBEP20(_USDT).balanceOf(address(this));
        require(balance >= amount, "Nothing to withdraw");
        IBEP20(_USDT).transfer(owner(), amount);
    }

    ////////////////////// INTERNAL FUNCTIONS ///////////////////////

    function _buy(uint256 amount) internal returns(uint256){
        uint256 loggAmount = amount;
        if(_price == 0) revert IncorrectPrice();
        uint256 usdtAmount = loggAmount * _price;// Safe since 0.8 solc

        uint256 prevBalance = IBEP20(_USDT).balanceOf(address(this));
        IBEP20(_USDT).transferFrom(msg.sender, address(this), usdtAmount);
        uint256 newBalance = IBEP20(_USDT).balanceOf(address(this));

        if(!(newBalance > prevBalance)) revert ToLowAmount();
        uint256 exactUsdtSpent = newBalance - prevBalance;
        if (exactUsdtSpent < 1000000000000000000) revert ToLowAmount();// Should be at least a dollar
        
        if (exactUsdtSpent < usdtAmount){
            uint256 exactLoggAmount = exactUsdtSpent / _price;
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