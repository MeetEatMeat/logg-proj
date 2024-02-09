// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/// @title An intermediate fundrising token
/// @author MeetEatMeat
/// @notice This token will be changed to a permanent LOGG token as 1:1
contract LOGGI is ERC20, Ownable {

    event Minted(address, uint);
    event Bought(address, uint);
    event Burned(address, uint);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    mapping(address => bool) public whitelist;
    bool public publicSaleStatus;
    uint256 private _price = 5000000000000000 wei;// 0,005 USDT
    uint256 private _totalSaleAmount;
    address public constant _USDT = 0x55d398326f99059fF775485246999027B3197955;

    error SaleNotActive();
    error ToLowAmount();
    error IncorrectAmount();
    error IncorrectAddress();
    error IncorrectCount();
    error NotEnoughTotalSaleAmount();
    error NotWhitelisted();

    constructor(uint256 totalAmount) ERC20("Logarithm Games Intermediate Token", "LOGGI") Ownable(msg.sender){
        _totalSaleAmount = totalAmount;
    }

    function mint(uint amount, address to) public onlyOwner {
        if (amount == 0) revert IncorrectAmount();
        if (to == address(this)) revert IncorrectAddress();

        _mint(to, amount);
        emit Minted(to, amount);
    }

    /// @notice This function is for public sale buyers
    function buy(uint256 amount) external returns(uint256){
        if (!publicSaleStatus) revert SaleNotActive();

        return _buy(amount);
    }

    function buyWl(uint256 amount) external returns(uint256){
        if (!whitelist[_msgSender()]) revert NotWhitelisted();

        return _buy(amount);
    }

    function _buy(uint256 amount) internal returns(uint256){
        if (amount < 1000000000000000000) revert ToLowAmount();// Should be at least a dollar

        uint256 count = amount / _price;
        if (count > _totalSaleAmount) revert NotEnoughTotalSaleAmount();
        if (!(count > 0)) revert IncorrectCount();

        IBEP20(_USDT).transferFrom(msg.sender, address(this), amount);

        _totalSaleAmount -= count;
        _mint(_msgSender(), count);

        emit Bought(_msgSender(), count);
        return count;
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        emit Burned(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function getPrice() external view returns (uint256){
        return _price;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function getSaleAmount() external view returns (uint256){
        return _totalSaleAmount;
    }

    function setSaleAmount(uint256 count) external onlyOwner {
        _totalSaleAmount = count;
    }

    function setSaleStatePublic(bool newSaleState) external onlyOwner {
        publicSaleStatus = newSaleState;
    }

    function addToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
    }

    function addToWhitelistBatch(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
        }
    }

    function removeFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
    }

    function isWhitelisted(address _user) external view returns (bool){
        return whitelist[_user];
    }

    function withdraw() external onlyOwner {
        IBEP20(_USDT).transfer(owner(),  IBEP20(_USDT).balanceOf(address(this)));
    }
}