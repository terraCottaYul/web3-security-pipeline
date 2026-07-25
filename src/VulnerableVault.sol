// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // VULNERABLE: Sends ether before modifying state variable intensionally to simulate a pitfall (Violates CEI)
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        // BUG
        balances[msg.sender] = 0;
    }
}
