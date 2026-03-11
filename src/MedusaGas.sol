// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Counter} from "./Counter.sol";

contract MedusaGas {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    uint256 constant MAX_GAS_SETNUMBER = 100000;
    uint256 constant MAX_GAS_INCREMENT = 50000000;
    uint256 constant MAX_GAS_DOBLE = 60000000;

    // O(1) - Constante (Hecho por la compañera/contexto general, alineado con uint16)
    function test_Constant(uint16 x) public {
        uint256 startGas = gasleft();
        counter.setNumber(x);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed <= MAX_GAS_SETNUMBER);
    }

    // O(n) - Lineal (Alineado con uint16)
    function test_Linear(uint16 times) public {
        if (uint256(counter.number()) + times > type(uint16).max) return;

        uint256 startGas = gasleft();
        counter.increment(times);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed <= MAX_GAS_INCREMENT);
    }

    // O(n^2) - Cuadrático (Mi parte: alineado al estilo natural de CounterTest)
    function test_Quadratic(uint16 a, uint16 b) public {
        uint256 mult = uint256(a) * uint256(b);
        if (mult > type(uint16).max) return;
        if (uint256(counter.number()) + mult > type(uint16).max) return;

        uint256 startGas = gasleft();
        counter.doble(a, b);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed <= MAX_GAS_DOBLE);
    }

    // Calldata Cost (Mi parte: midiendo calldata nativamente)
    function test_Calldata(uint256 a) public {
        // En Medusa el calldata completo se incluye en la transacción de fuzzing.
        // Hacemos el warmup y medimos la diferencia al estilo de Foundry.
        counter.checkcalldata(0);

        uint256 gas1 = gasleft();
        counter.checkcalldata(0);
        uint256 gas2 = gasleft();

        uint256 gas3 = gasleft();
        counter.checkcalldata(a);
        uint256 gas4 = gasleft();

        uint256 baseline = gas1 - gas2;
        uint256 actual = gas3 - gas4;

        // Assert: sending more non-zero bytes uses the same execution gas,
        // but intrinsic gas isn't captured perfectly by gasleft().
        // We assert the internal execution is constant (O(1)).
        assert(actual <= baseline + 1000);
    }
}
