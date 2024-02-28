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
        vm.label(address(_owner), "OWNER");
        _wluser1 = vm.addr(0x0002);
        vm.label(address(_wluser1), "USER1");
        _wluser2 = vm.addr(0x0003);
        vm.label(address(_wluser2), "USER2");
        _wluser3 = vm.addr(0x0004);
        vm.label(address(_wluser3), "USER3");
        _wluser4 = vm.addr(0x0005);
        vm.label(address(_wluser4), "USER4");
        _psuser = vm.addr(0x0006);
        _logg = new LOGG(_totalSaleAmount, address(_owner));
        vm.startPrank(_owner);
        _logg.setSaleStatus(true);
        _logg.setToken(address(_USDT));
        vm.stopPrank();
    }

    function test_buyForUSDT() public {
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
        _logg.buyForUSDT(exactUSDT);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), 2000e18);
    }

    function testFail_buyForUSDT() public {
        uint256 exactUSDT = _logg.getExactUSDTAmount(2000e18);
        vm.startPrank(_wluser1);
        // Wasn't approved
        _logg.buyForUSDT(exactUSDT);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), 2000e18);
    }

    function testFuzz_buyForUSDT(uint256 loggAmount) public {
        vm.assume(loggAmount > 200);
        vm.assume(loggAmount <= 1000000);

        vm.assume(((loggAmount * 1e18) + _logg.totalSupply()) <= 1_000_000_000e18);
        vm.assume((loggAmount * 1e18) < _logg.getSaleTotalAmount());
        uint256 exactUSDT = _logg.getExactUSDTAmount(loggAmount * 1e18);

        uint256 balanceBefore = _USDT.balanceOf(_wluser1);
        console.log("Balance before: ", balanceBefore);
        deal(address(_USDT), _wluser1, exactUSDT, true);
        uint256 balanceAfter = _USDT.balanceOf(_wluser1);
        console.log("Balance after: ", balanceAfter);
        assertGt(balanceAfter, balanceBefore);

        vm.startPrank(_wluser1);
        _USDT.approve(address(_logg), exactUSDT);
        console.log("USDT to LOGG allowance: ", _USDT.allowance(address(_wluser1), address(_logg)));
        _logg.buyForUSDT(exactUSDT);
        vm.stopPrank();
        assertEq(_logg.balanceOf(_wluser1), loggAmount * 1e18);
    }

    function test_buyForBNB() public {
        // uint256 exactBNB = _logg.getExactBNBAmount(2000e18);

        deal(_wluser1, 1 ether);

        vm.prank(_wluser1);
        uint256 bought = _logg.buyForBNB{value: 1 ether}();
        assertEq(_logg.balanceOf(_wluser1), bought);
    }

    function test_totalSaleAmountDecrease() public{
        deal(_wluser1, 1 ether);
        uint256 totalSaleAmount = _logg.getSaleTotalAmount();
        vm.prank(_wluser1);
        uint256 bought = _logg.buyForBNB{value: 1 ether}();
        assertEq(_logg.getSaleTotalAmount(), totalSaleAmount - bought);
    }

    function test_Getters() public {
        assertEq(_logg.getSaleTotalAmount(), _totalSaleAmount);
        assertEq(_logg.decimals(), 18);
        assertEq(_logg.getUSDTPrice(), 5e15);
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

    function test_setUSDTPrice() public {
        vm.prank(_owner);
        _logg.setUSDTPrice(6e15);
        assertEq(_logg.getUSDTPrice(), 6e15);
    }

    function testFail_setUSDTPrice() public {
        _logg.setUSDTPrice(6e15);
        assertEq(_logg.getUSDTPrice(), 6e15);
    }

    function testFuzz_setUSDTPrice(uint256 price) public {
        vm.assume(price > 0);
        vm.prank(_owner);
        _logg.setUSDTPrice(price);
        assertEq(_logg.getUSDTPrice(), price);
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

    function test_withdrawAll() public {
        uint256 wluser1Amount = 1 ether;
        uint256 wluser2Amount = 1000e18;
        uint256 wluser3Amount = 500e18;

        deal(_wluser1, wluser1Amount);
        deal(address(_USDT), _wluser2, wluser2Amount, true);
        deal(address(_USDT), _wluser3, wluser3Amount, true);

        vm.prank(_wluser2);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser3);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser1);
        _logg.buyForBNB{value: wluser1Amount}();

        vm.prank(_wluser2);
        _logg.buyForUSDT(wluser2Amount);

        vm.prank(_wluser3);
        _logg.buyForUSDT(wluser3Amount);

        vm.prank(_owner);
        _logg.withdrawAll();

        assertEq(_USDT.balanceOf(address(_owner)), wluser2Amount + wluser3Amount);
        assertEq(address(_owner).balance, wluser1Amount);
    }

    function testFail_withdrawAll() public {
        uint256 wluser1Amount = 1 ether;
        uint256 wluser2Amount = 1000e18;
        uint256 wluser3Amount = 500e18;

        deal(_wluser1, wluser1Amount);
        deal(address(_USDT), _wluser2, wluser2Amount, true);
        deal(address(_USDT), _wluser3, wluser3Amount, true);

        vm.prank(_wluser2);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser3);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser1);
        _logg.buyForBNB{value: wluser1Amount}();

        vm.prank(_wluser2);
        _logg.buyForUSDT(wluser2Amount);

        vm.prank(_wluser3);
        _logg.buyForUSDT(wluser3Amount);

        vm.prank(_wluser1);
        _logg.withdrawAll();
    }

    function test_withdrawUSDT() public {
        uint256 wluser2Amount = 1000e18;
        uint256 wluser3Amount = 500e18;

        deal(address(_USDT), _wluser2, wluser2Amount, true);
        deal(address(_USDT), _wluser3, wluser3Amount, true);

        vm.prank(_wluser2);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser3);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser2);
        _logg.buyForUSDT(wluser2Amount);

        vm.prank(_wluser3);
        _logg.buyForUSDT(wluser3Amount);

        console.log("Current LOGG owner: ", _logg.owner());
        console.log("Owner that called withdraw: ", _owner);
        vm.prank(_owner);
        _logg.withdrawUSDT(_USDT.balanceOf(address(_logg)));

        assertEq(_USDT.balanceOf(address(_owner)), wluser2Amount + wluser3Amount);
    }

    function testFail_withdrawUSDT() public {
        uint256 wluser2Amount = 1000e18;
        uint256 wluser3Amount = 500e18;

        deal(address(_USDT), _wluser2, wluser2Amount, true);
        deal(address(_USDT), _wluser3, wluser3Amount, true);

        vm.prank(_wluser2);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser3);
        _USDT.approve(address(_logg), UINT256_MAX);

        vm.prank(_wluser2);
        _logg.buyForUSDT(wluser2Amount);

        vm.prank(_wluser3);
        _logg.buyForUSDT(wluser3Amount);

        vm.prank(_wluser1);
        _logg.withdrawUSDT(_USDT.balanceOf(address(_logg)));
    }

    function test_withdrawBNB() public {
        uint256 wluser1Amount = 1 ether;
        uint256 wluser2Amount = 3 ether;
        deal(_wluser1, wluser1Amount);
        deal(_wluser2, wluser2Amount);

        vm.prank(_wluser1);
        _logg.buyForBNB{value: wluser1Amount}();

        vm.prank(_wluser2);
        _logg.buyForBNB{value: wluser2Amount}();

        vm.prank(_owner);
        _logg.withdrawBNB(address(_logg).balance);

        assertEq(address(_owner).balance, wluser1Amount + wluser2Amount);
    }

    function testFail_withdrawBNB() public {
        uint256 wluser1Amount = 1 ether;
        uint256 wluser2Amount = 3 ether;
        deal(_wluser1, wluser1Amount);
        deal(_wluser2, wluser2Amount);

        vm.prank(_wluser1);
        _logg.buyForBNB{value: wluser1Amount}();

        vm.prank(_wluser2);
        _logg.buyForBNB{value: wluser2Amount}();

        vm.prank(_wluser1);
        _logg.withdrawBNB(address(_logg).balance);
    }
}