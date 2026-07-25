// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VulnerableVault.sol";

contract VaultTest is Test {
    VulnerableVault public vault;

    function setUp() public {
        vault = new VulnerableVault();
    }

    function testDeposit() public {
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(address(this)), 1 ether);
    }
}
