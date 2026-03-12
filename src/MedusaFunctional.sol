// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Counter.sol";

// Contrato de prueba para evaluar la exactitud MATEMÁTICA con Medusa
// Aquí no medimos gas, medimos que las operaciones hagan lo que deben hacer
contract MedusaFunctional {
    Counter public counter;

    constructor() {
        counter = new Counter();
    }

    // Evaluación Funcional 1: ¿La función setNumber guarda exactamente el número x?
    function test_functional_setNumber(uint16 x) public {
        counter.setNumber(x);
        
        // Aserción: El número dentro de counter DEBE ser igual al enviado
        assert(counter.number() == x);
    }

    // Evaluación Funcional 2: ¿La función increment suma de verdad 'times' al saldo?
    function test_functional_increment(uint16 x, uint16 times) public {
        // Fijamos un número base aleatorio
        counter.setNumber(x);
        uint256 preNumber = counter.number();
        
        // Evitamos que falle por matemáticass (Overflow nativo del uint16)
        if (preNumber + uint256(times) > type(uint16).max) {
            return;
        }

        counter.increment(times);
        
        // Aserción: El nuevo número DEBE SER igual al anterior más 'times'
        assert(counter.number() == preNumber + times);
    }

    // Evaluación Funcional 3: ¿La función doble suma su multiplicación correctamente?
    function test_functional_doble(uint16 x, uint16 a, uint16 b) public {
        counter.setNumber(x);
        uint256 preNumber = counter.number();
        
        uint256 mult = uint256(a) * uint256(b);
        
        // Filtramos para probar solo números procesables sin overlow
        if (mult > type(uint16).max) return;
        if (preNumber + mult > type(uint16).max) return;

        counter.doble(a, b);
        
        // Aserción: El bucle debe haber sumado exactamente a * b
        assert(counter.number() == preNumber + mult);
    }
}
