// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LOGGToken is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    constructor(address privateSaleContract, address loggVault) ERC20("Logarithm Games", "LOGG"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint()

    }

}
