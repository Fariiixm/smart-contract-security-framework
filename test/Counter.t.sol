// Archivo: test/CounterGas.t.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Test} from "forge-std/Test.sol";
// Asegúrate de que la ruta apunte correctamente a src
import {Counter} from "../src/Counter.sol";

contract CounterGas is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    // Límite de gas que queremos permitir (Budget de Gas)
    uint256 constant MAX_GAS_SETNUMBER = 100000;
    uint256 constant MAX_GAS_INCREMENT = 50000000;
    uint256 constant MAX_GAS_DOBLE = 60000000;

    // CASO DE USO 1: Fuzzing simple + Medición de Gas
    function testGasSetNumber(uint16 x) public {
        uint256 gasStart = gasleft(); // Foto del gas inicial
        counter.setNumber(x);
        uint256 gasUsed = gasStart - gasleft(); // Cálculo del consumo

        // Aserción: Si gasta más de lo permitido, el test falla
        assertLe(gasUsed, MAX_GAS_SETNUMBER, "Gas excedido en setNumber");
    }

    // CASO DE USO 2: Fuzzing con bucles y restricciones (Assumes)
    function testGasIncrement(uint16 x, uint16 times) public {
        // vm.assume le dice al Fuzzer: "No pruebes valores que no cumplan esto"
        // Evitamos overflow manual del uint8 para que el test se centre en el gas
        vm.assume(uint256(x) + uint256(times) <= type(uint16).max);

        counter.setNumber(x);

        uint256 gasStart = gasleft();
        counter.increment(times);
        uint256 gasUsed = gasStart - gasleft();

        assertLe(gasUsed, MAX_GAS_INCREMENT, "Gas excedido en increment");
    }

    // CASO DE USO 3: Bucles anidados (Complejidad Cuadrática)
    function testGasDoble(uint16 x, uint16 a, uint16 b) public {
        // Restricción para evitar overflow matemático en la precondición
        uint256 mult = uint256(a) * uint256(b);

        //Evitamos desbordamiento
        vm.assume(mult <= type(uint16).max);
        vm.assume(uint256(x) + mult <= type(uint16).max);

        counter.setNumber(x);

        uint256 gasStart = gasleft();
        counter.doble(a, b);
        uint256 gasUsed = gasStart - gasleft();

        assertLe(gasUsed, MAX_GAS_DOBLE, "Gas excedido en doble bucle");
    }

    // CASO DE USO 4: Coste de Calldata (Datos de entrada)
    function testGasCallData(uint256 a) public {
        // warm-up
        counter.checkcalldata(0);

        uint256 gas1 = gasleft();
        counter.checkcalldata(0);
        uint256 gas2 = gasleft();

        counter.checkcalldata(115792089237316195423570985008687907853269984665640564039457584007913129639935);
        uint256 gas3 = gasleft();

        uint256 gasUsed1 = gas1 - gas2;
        uint256 gasUsed2 = gas2 - gas3;

        //La primera llamada debe consumir menos gas que la segunda
        assertEq(gasUsed2, gasUsed1, "No tiene en cuenta CallData");
    }
}
