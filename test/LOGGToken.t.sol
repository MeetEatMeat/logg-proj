// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Test.sol";
import "../src/LOGGToken.sol";
import "../src/IBEP.sol";
import "forge-std/StdUtils.sol";

contract LOGGTest is Test {
    LOGG public _logg;
    address _owner;
    uint256 _totalSaleAmount;
    address _wluser1;
    address _wluser2;
    address _wluser3;
    address _wluser4;
    address _psuser;
    address[] users;
    IBEP20 public USDT;

    function setUp() public {
        USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        _totalSaleAmount = 1000000e18;
        _owner = vm.addr(0x0001);
        _wluser1 = vm.addr(0x0002);
        _wluser2 = vm.addr(0x0003);
        _wluser3 = vm.addr(0x0004);
        _wluser4 = vm.addr(0x0005);
        _psuser = vm.addr(0x0006);
        _logg = new LOGG(_totalSaleAmount, _owner);
        vm.prank(_owner);
        _logg.setSaleStatus(true);
    }

    function test_Getters() public {
        assertEq(_logg.getSaleTotalAmount(), _totalSaleAmount);
        assertEq(_logg.decimals(), 18);
        assertEq(_logg.getPrice(), 5e15);
        assertEq(_logg.getSaleStatus(), true);
    }

    function test_setSaleTotalAmount() public {
        uint256 newSaleAmount = _totalSaleAmount * 2;
        vm.prank(_owner);
        _logg.setSaleTotalAmount(newSaleAmount);
        assertEq(_logg.getSaleTotalAmount(), newSaleAmount);
    }

    function test_setPrice() public {
        vm.prank(_owner);
        _logg.setPrice(6e15);
        assertEq(_logg.getPrice(), 6e15);
    }

    function test_mint() public {
        vm.prank(_owner);
        _logg.mint(100e18, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 100e18);
    }

    function test_burn() public {
        vm.prank(_owner);
        _logg.mint(100e18, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 100e18);
        _logg.burn(_logg.balanceOf(_wluser4), _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 0);
    }

    function test_buy() public {
        deal(address(USDT), _wluser1, 200e18);
        vm.prank(_wluser1);
        _logg.buy(100e18);
        assertEq(_logg.balanceOf(_wluser1), 100e18);
    }
}