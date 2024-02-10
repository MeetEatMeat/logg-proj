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
/// @notice LOGGI holders will be allowed to change their LOGGI tokens to LOGG token as 1:1
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
    address public constant _OWNER = ;

    error SaleNotActive();
    error ToLowAmount();
    error IncorrectAmount();
    error IncorrectAddress();
    error NotEnoughTotalSaleAmount();
    error NotWhitelisted();
    error IncorrectPrice();
    error AlreadyWhitelisted();

    constructor(uint256 totalAmount) ERC20("Logarithm Games Intermediate Token", "LOGGI") Ownable(_OWNER){
        _totalSaleAmount = totalAmount;
    }

    /// @notice This function is for public sale buyers
    /// @param amount Amount is amount of USDT that buyer supposes to spend
    /// @return Return the bought amount of LOGGI tokens
    function buy(uint256 amount) external returns(uint256){
        if (!publicSaleStatus) revert SaleNotActive();

        return _buy(amount);
    }

    /// @notice This function is for whitelisted buyers
    /// @param amount Amount is amount of USDT that buyer supposes to spend
    /// @return Return the bought amount of LOGGI tokens
    function buyWl(uint256 amount) external returns(uint256){
        if (!whitelist[_msgSender()]) revert NotWhitelisted();

        return _buy(amount);
    }

    function _buy(uint256 usdtAmount) internal returns(uint256){
        uint256 prevBalance = IBEP20(_USDT).balanceOf(address(this));
        IBEP20(_USDT).transferFrom(msg.sender, address(this), usdtAmount);
        uint256 newBalance = IBEP20(_USDT).balanceOf(address(this));

        if(!(newBalance > prevBalance)) revert ToLowAmount();
        uint256 exactUsdtSpent = newBalance - prevBalance;
        if (exactUsdtSpent < 1000000000000000000) revert ToLowAmount();// Should be at least a dollar

        if(_price == 0) revert IncorrectPrice();
        uint256 loggiAmount = exactUsdtSpent / _price;

        if (loggiAmount > _totalSaleAmount) revert NotEnoughTotalSaleAmount();
        if (!(loggiAmount > 0)) revert IncorrectAmount();

        _totalSaleAmount -= loggiAmount;
        _mint(_msgSender(), loggiAmount);

        emit Bought(_msgSender(), loggiAmount);
        return loggiAmount;
    }

    /// @dev In BSC chain the USDT token has 18 digits so we have to use 18 digits with LOGGI token
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function getPrice() external view returns (uint256){
        return _price;
    }

    function getSaleAmount() external view returns (uint256){
        return _totalSaleAmount;
    }

    function isWhitelisted(address _user) external view returns (bool){
        return whitelist[_user];
    }

    ////////////////////// OWNER'S FUNCTIONS ///////////////////////

    /// @notice This function is for minting tokens
    /// @param amount Amount of tokens to mint
    function mint(uint amount, address to) public onlyOwner {
        if (amount == 0) revert IncorrectAmount();
        if (to == address(this)) revert IncorrectAddress();

        _mint(to, amount);
        emit Minted(to, amount);
    }

    function setPrice(uint256 price) external onlyOwner {
        if(price == 0) revert IncorrectPrice();
        _price = price;
    }

    function setSaleAmount(uint256 amount) external onlyOwner {
        if(amount == 0) revert IncorrectAmount();
        _totalSaleAmount = amount;
    }

    /// @notice This function close or open public sale
    /// @param newSaleState If this param is true sale is opened and otherwise sale is closed
    function setSaleStatePublic(bool newSaleState) external onlyOwner {
        publicSaleStatus = newSaleState;
    }

    /// @notice A function to add a single user into whitelist
    function addToWhitelist(address _user) external onlyOwner {
        _addToWhitelist(_user);
    }

    /// @notice A function to add a batch of users into whitelist
    /// @param _users An array of adresses to add into whitelist
    function addToWhitelistBatch(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            _addToWhitelist(_users[i]);
        }
    }

    function _addToWhitelist(address _user) internal {
        if(whitelist[_user]) revert AlreadyWhitelisted();
        whitelist[_user] = true;
        emit AddedToWhitelist(_user);
    }

    function removeFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
        emit RemovedFromWhitelist(_user);
    }

    function withdraw() external onlyOwner {
        uint256 amountToWithdraw = IBEP20(_USDT).balanceOf(address(this));
        require(amountToWithdraw > 0, "Nothing to withdraw");
        IBEP20(_USDT).transfer(owner(),  amountToWithdraw);
    }
}