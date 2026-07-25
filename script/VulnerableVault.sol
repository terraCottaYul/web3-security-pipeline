// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VulnerableVault.sol";

contract CounterScript is Script {
    function run() public {
        vm.startBroadcast();
        new VulnerableVault();
        vm.stopBroadcast();
    }
}
