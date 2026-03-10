// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Counter} from "./Counter.sol";

contract MedusaGas {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    // O(1) - Constante
    function Constant(uint8 x) public {
        uint256 startGas = gasleft();
        counter.setNumber(x);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed < 30000);
    }

    // O(n) - Lineal
    function Linear(uint8 times) public {
        uint256 startGas = gasleft();
        counter.increment(times);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed < 100000);
    }

    // O(n^2) - Cuadrático
    function Quadratic(uint8 a, uint8 b) public {
        uint256 startGas = gasleft();
        counter.doble(a, b);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed < 179000);
    }

    // Calldata Cost
    function test_Calldata(
        uint256 a
    ) public {
        uint256 startGas = gasleft();
        counter.checkcalldata(a);
        uint256 gasUsed = startGas - gasleft();
        assert(gasUsed < 9000);
    }
}
