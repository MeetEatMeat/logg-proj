// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Test.sol";
import "../src/IntermediateToken.sol";

contract LOGGITest is Test {
    LOGGI public loggi;
    address owner;
    uint256 totalAlloc;

    function setUp() public {
        totalAlloc = 1000000e18;
        owner = vm.addr(123);
        loggi = new LOGGI(totalAlloc, owner);
    }
}