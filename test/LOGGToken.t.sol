// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LOGGToken.sol";
import {IBEP20} from "../src/IBEP.sol";
import {USDT} from "../lib/USDT.sol";
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
    USDT public _USDT;

    function setUp() public {
        _USDT = new USDT();
        _totalSaleAmount = 1000000e18;
        _owner = vm.addr(0x0001);
        _wluser1 = vm.addr(0x0002);
        _wluser2 = vm.addr(0x0003);
        _wluser3 = vm.addr(0x0004);
        _wluser4 = vm.addr(0x0005);
        _psuser = vm.addr(0x0006);
        _logg = new LOGG(_totalSaleAmount, _owner);
        vm.startPrank(_owner);
        _logg.setSaleStatus(true);
        _logg.setToken(address(_USDT));
        vm.stopPrank();
    }

    function test_buy() public {
        uint256 exactUSDT = _logg.getExactUSDTAmount(2000e18);

        uint256 balanceBefore = _USDT.balanceOf(_wluser1);
        console.log("Balance before: ", balanceBefore);
        deal(address(_USDT), _wluser1, exactUSDT, true);
        uint256 balanceAfter = _USDT.balanceOf(_wluser1);
        console.log("Balance after: ", balanceAfter);
        assertGt(balanceAfter, balanceBefore);

        vm.startPrank(_wluser1);
        _USDT.approve(address(_logg), exactUSDT);
        console.log("USDT to LOGG allowance: ", _USDT.allowance(address(_wluser1), address(_logg)));
        _logg.buy(2000e18);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), 2000e18);
    }

    function testFail_buy() public {
        vm.startPrank(_wluser1);
        _logg.buy(2000e18);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), 100e18);
    }

    function testFuzz_buy(uint256 loggAmount) public {
        vm.assume((loggAmount + _logg.totalSupply()) <= 1_000_000_000e18);
        vm.assume(loggAmount < _logg.getSaleTotalAmount());
        vm.assume(loggAmount > 200e18);
        uint256 exactUSDT = _logg.getExactUSDTAmount(loggAmount);

        uint256 balanceBefore = _USDT.balanceOf(_wluser1);
        console.log("Balance before: ", balanceBefore);
        deal(address(_USDT), _wluser1, exactUSDT, true);
        uint256 balanceAfter = _USDT.balanceOf(_wluser1);
        console.log("Balance after: ", balanceAfter);
        assertGt(balanceAfter, balanceBefore);

        vm.startPrank(_wluser1);
        _USDT.approve(address(_logg), exactUSDT);
        console.log("USDT to LOGG allowance: ", _USDT.allowance(address(_wluser1), address(_logg)));
        _logg.buy(loggAmount);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), loggAmount);
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

    function testFail_setSaleTotalAmount() public {
        uint256 newSaleAmount = _totalSaleAmount * 2;
        _logg.setSaleTotalAmount(newSaleAmount);
        assertEq(_logg.getSaleTotalAmount(), newSaleAmount);
    }

    function testFuzz_setSaleTotalAmount(uint256 amount) public {
        vm.assume(amount > 0);
        vm.prank(_owner);
        _logg.setSaleTotalAmount(amount);
        assertEq(_logg.getSaleTotalAmount(), amount);
    }

    function test_setPrice() public {
        vm.prank(_owner);
        _logg.setPrice(6e15);
        assertEq(_logg.getPrice(), 6e15);
    }

    function testFail_setPrice() public {
        _logg.setPrice(6e15);
        assertEq(_logg.getPrice(), 6e15);
    }

    function testFuzz_setPrice(uint256 price) public {
        vm.assume(price > 0);
        vm.prank(_owner);
        _logg.setPrice(price);
        assertEq(_logg.getPrice(), price);
    }

    function test_mint() public {
        vm.prank(_owner);
        _logg.mint(100e18, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 100e18);
    }

    function testFail_mint() public {
        _logg.mint(100e18, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 100e18);
    }

    function test_burn() public {
        vm.startPrank(_owner);
        _logg.mint(100e18, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 100e18);
        _logg.burn(_logg.balanceOf(_wluser4), _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 0);
        vm.stopPrank();
    }

    function testFail_burn() public {
        _logg.burn(_logg.balanceOf(_wluser4), _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 0);
    }

    function testFuzz_burn(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume((amount + _logg.totalSupply()) <= 1_000_000_000e18);
        vm.startPrank(_owner);
        _logg.mint(amount, _wluser4);
        assertEq(_logg.balanceOf(_wluser4), amount);
        _logg.burn(_logg.balanceOf(_wluser4), _wluser4);
        assertEq(_logg.balanceOf(_wluser4), 0);
        vm.stopPrank();
    }

    function testFail_withdrawAll() public {
        _logg.withdrawAll();
    }

    function testFail_withdraw() public {
        _logg.withdraw(_USDT.balanceOf(address(_logg)));
    }
}