// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Reentrancy.sol";

interface Vm {
    function deal(address, uint256) external;
    function prank(address) external;
}

contract ReentrancyMedusa {
    VulnerableBank bank;

    // Cheatcode address for Foundry/Medusa
    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // Track funds
    uint256 public my_deposits;
    uint256 public total_received;

    constructor() {
        bank = new VulnerableBank();

        // SIMULACIÓN DE VICTIMA:
        // En lugar de simular un usuario completo con prank,
        // simplemente inyectamos ETH "extra" al banco para que sea solvente.
        vm.deal(address(bank), 100 ether);
    }

    // Allow Medusa to deposit
    function deposit() public payable {
        bank.deposit{value: msg.value}();
        my_deposits += msg.value;
    }

    // Allow Medusa to withdraw
    function withdraw() public {
        bank.withdraw();
    }

    // Property: We should never profit from the bank (receive more than we deposited)
    function property_no_profit() public view returns (bool) {
        return total_received <= my_deposits;
    }

    receive() external payable {
        // Solo contamos dinero si viene del banco
        if (msg.sender == address(bank)) {
            total_received += msg.value;
        }

        // Attack Logic:
        // Si recibimos fondos del banco, intentamos sacar MÁS.
        // Limitamos el gas para evitar Out of Gas.
        if (address(bank).balance >= 1 ether && gasleft() > 5000) {
            try bank.withdraw() {} catch {}
        }
    }
}
