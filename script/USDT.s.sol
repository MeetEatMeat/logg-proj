// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../lib/USDT.sol";

contract LOGGScript is Script {
    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIV_KEY");
        address account = vm.addr(privateKey);
        console.log("Account: ", account);
        vm.startBroadcast(address(account));
        USDT usdt = new USDT();
        usdt.mint(1000e18);
        vm.stopBroadcast();
    }
}