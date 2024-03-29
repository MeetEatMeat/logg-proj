// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/LOGGToken.sol";

contract LOGGScript is Script {
    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIV_KEY");
        address account = vm.addr(privateKey);
        console.log("Account: ", account);
        vm.startBroadcast(address(account));
        LOGG loggToken = new LOGG(1_000_000e18, account);
        USDT usdt = new USDT();
        loggToken.setToken(address(usdt));
        usdt.mint(1000e18);
        usdt.approve(address(loggToken), UINT256_MAX);
        loggToken.setSaleStatus(true);
        vm.stopBroadcast();
    }
}
