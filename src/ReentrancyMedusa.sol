// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Reentrancy.sol";

// Un contrato de prueba "natural" para Medusa
// No incluye lógica de ataque hardcodeada, deja que el fuzzer descubra asincronías.
contract ReentrancyMedusa {
    VulnerableBank public bank;

    uint256 public totalDeposits;

    constructor() {
        bank = new VulnerableBank();
    }

    // Envoltorio natural para simular depósitos generales
    function deposit() public payable {
        bank.deposit{value: msg.value}();
        totalDeposits += msg.value;
    }

    // Envoltorio natural para que la herramienta intente retirar
    function withdraw() public {
        // Obtenemos el balance antes para saber si debiera fallar o no
        uint256 bal = bank.balances(address(this));
        if (bal > 0) {
            bank.withdraw();
            // Actualizamos la contabilidad si fue exitoso (en un entorno sin vulnerabilidad)
            totalDeposits -= bal;
        } else {
            // Intentar retirar sin balance, natural fuzzing
            try bank.withdraw() {} catch {}
        }
    }

    // PROPIEDAD NATURAL: El balance real del banco nunca debe ser menor
    // a los depósitos registrados.
    // Si Medusa (u otro fuzzer avanzado) implementa re-entradas estándar en sus callers,
    // el banco enviará ETH y no restará el balance hasta el final, filtrando ETH real vs contable.
    function property_solvency() public view returns (bool) {
        return address(bank).balance >= totalDeposits;
    }
}
