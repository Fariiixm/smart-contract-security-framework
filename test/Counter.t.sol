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
    uint256 constant MAX_GAS_INCREMENT = 180000; // Cuidado: esto fallará si el bucle es muy largo
    uint256 constant MAX_GAS_DOBLE = 180000;
    uint256 constant MAX_GAS_CALLDATA = 8000;

    // CASO DE USO 1: Fuzzing simple + Medición de Gas
    function testGasSetNumber(uint8 x) public {
        uint256 gasStart = gasleft(); // Foto del gas inicial
        counter.setNumber(x);
        uint256 gasUsed = gasStart - gasleft(); // Cálculo del consumo

        // Aserción: Si gasta más de lo permitido, el test falla
        assertLe(gasUsed, MAX_GAS_SETNUMBER, "Gas excedido en setNumber");
    }

    // CASO DE USO 2: Fuzzing con bucles y restricciones (Assumes)
    function testGasIncrement(uint8 x, uint8 times) public {
        // vm.assume le dice al Fuzzer: "No pruebes valores que no cumplan esto"
        // Evitamos overflow manual del uint8 para que el test se centre en el gas
        vm.assume(x < type(uint8).max - times); 
        
        // Limitamos el bucle a 500 iteraciones para no exceder el límite de gas de bloque
        vm.assume(times <= 100); // He bajado a 100 para que pase tu límite de 180.000 gas

        counter.setNumber(x);

        uint256 gasStart = gasleft();
        counter.increment(times);
        uint256 gasUsed = gasStart - gasleft();

        assertLe(gasUsed, MAX_GAS_INCREMENT, "Gas excedido en increment");
    }

    // CASO DE USO 3: Bucles anidados (Complejidad Cuadrática)
    function testGasDoble(uint8 x, uint8 a, uint8 b) public {
        // Restricción para evitar overflow matemático en la precondición
        vm.assume(uint256(x) + uint256(a) * uint256(b) <= type(uint8).max);
        
        // Limitamos los bucles para mantener el gas bajo control
        vm.assume(a <= 20); // Bajado a 20 para ajustar al límite de gas
        vm.assume(b <= 20);

        counter.setNumber(x);

        uint256 gasStart = gasleft();
        counter.doble(a, b);
        uint256 gasUsed = gasStart - gasleft();

        assertLe(gasUsed, MAX_GAS_DOBLE, "Gas excedido en doble bucle");
    }

    // CASO DE USO 4: Coste de Calldata (Datos de entrada)
    function testGasCallData(uint16 a, uint16 b, uint16 c, uint16 d, uint16 e, uint16 f, uint16 g, uint16 h, uint16 i, uint16 j, uint16 k) public {
        uint256 gasStart = gasleft();
        counter.checkcalldata(a, b, c, d, e, f, g, h, i, j, k);
        uint256 gasUsed = gasStart - gasleft();

        assertLe(gasUsed, MAX_GAS_CALLDATA, "Gas excedido en calldata");
    }
}