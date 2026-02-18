// Archivo: src/Counter.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Counter {
    uint8 public number;

    function setNumber(uint8 newNumber) public {
        number = newNumber;
    }

    function increment(uint8 times) public {
        for(uint8 i = 0; i < times; i++){
            number++;
        }
    }

    function doble(uint8 a, uint8 b) public {
        for(uint8 i = 0; i < a; i++){
            for(uint8 j = 0; j < b; j++){
                number++;
            }
        }
    }

    function checkcalldata(uint16 a, uint16 b, uint16 c, uint16 d, uint16 e, uint16 f, uint16 g, uint16 h, uint16 i, uint16 j, uint16 k) public {
        // Esta función está vacía para medir solo el coste de enviar los datos (calldata)
    }
}