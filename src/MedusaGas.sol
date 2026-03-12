// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Counter.sol";

// Contrato de prueba para Medusa enfocado en evaluar vulnerabilidades de Gas
contract MedusaGas {
    Counter public counter;

    constructor() {
        counter = new Counter();
    }

    // Proxy para probar la vulnerabilidad cuadrática
    // Como Medusa por defecto ignora los "Out of Gas" reales de la EVM (los considera descartables),
    // vamos a usar el mismo truco que en Foundry: Medir el gas manualmente y lanzar un ASSERT
    // si pasa el margen de los 60 millones. Esto hará que la herramienta pete en Rojo.
    function test_doble(uint16 x, uint16 a, uint16 b) public {
        // Reproducimos las precondiciones naturales
        uint256 mult = uint256(a) * uint256(b);
        require(mult <= type(uint16).max, "Math limits");
        require(uint256(x) + mult <= type(uint16).max, "Math limits");

        uint256 gasStart = gasleft();
        
        counter.setNumber(x);
        counter.doble(a, b);
        
        uint256 gasUsed = gasStart - gasleft();
        
        // Aserción empírica que romperá Media. El Test fallará mostrando que pasó la línea roja.
        assert(gasUsed < 60000000); 
    }

    // Proxy para evaluar Calldata
    function checkcalldata(uint256 a) public {
        counter.checkcalldata(a);
    }

    // PROPIEDAD DUMMY
    // En las pruebas de gas por DoS (Block Gas Limit), no buscamos quebrar una variable lógica,
    // buscamos quebrar la disponibilidad de la red superando el coste computacional.
    // Medusa descubrirá la vulnerabilidad al reportar transacciones que revientan el límite.
    function property_alive() public view returns (bool) {
        return address(counter) != address(0);
    }
}
