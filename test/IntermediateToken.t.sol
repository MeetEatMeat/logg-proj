// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Test.sol";
import "../src/IntermediateToken.sol";

contract LOGGITest is Test {
    LOGGI public _loggi;
    address _owner;
    uint256 _totalSaleAmount;
    address _wluser1;
    address _wluser2;
    address _wluser3;
    address _wluser4;
    address _psuser;
    address[] users;

    function setUp() public {
        _totalSaleAmount = 1000000e18;
        _owner = vm.addr(0x0001);
        _wluser1 = vm.addr(0x0002);
        _wluser2 = vm.addr(0x0003);
        _wluser3 = vm.addr(0x0004);
        _wluser4 = vm.addr(0x0005);
        _psuser = vm.addr(0x0006);
        _loggi = new LOGGI(_totalSaleAmount, _owner);
        vm.prank(_owner);
        _loggi.setSaleStatus(true);
    }

    function test_Getters() public {
        assertEq(_loggi.getSaleAmount(), _totalSaleAmount);
        assertEq(_loggi.decimals(), 18);
        assertEq(_loggi.getPrice(), 5e15);
        assertEq(_loggi.isWhitelisted(_psuser), false);
        assertEq(_loggi.getSaleStatus(), true);
    }

    function test_wlAddition() public {
        users = [
            _wluser1,
            _wluser2,
            _wluser3
        ];
        vm.startPrank(_owner);
        _loggi.addToWhitelistBatch(users);
        _loggi.addToWhitelist(_wluser4);
        vm.stopPrank();
        assertEq(_loggi.getWLTotal(), 4);
    }

    function test_removeFromWL() public {
        vm.prank(_owner);
        _loggi.removeFromWhitelist(_wluser4);
        assertEq(_loggi.getWLTotal(), 3);
    }

    function test_setSaleAmount() public {
        uint256 newSaleAmount = _totalSaleAmount * 2;
        vm.prank(_owner);
        _loggi.setSaleAmount(newSaleAmount);
        assertEq(_loggi.getSaleAmount(), newSaleAmount);
    }

    function test_setPrice() public {
        vm.prank(_owner);
        _loggi.setPrice(6e15);
        assertEq(_loggi.getPrice(), 6e15);
    }

    function test_Mint() public {
        vm.prank(_owner);
        _loggi.mint(100e18, _wluser4);
        assertEq(_loggi.balanceOf(_wluser4), 100e18);
    }
}