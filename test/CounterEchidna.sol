// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Counter.sol";

contract EchidnaCounterTest is Counter {
    uint16 internal valueIncrement;
    uint16 internal valueDoble;
    uint16 public fuzzNumber;

    function increment(uint16 times) public override {
        //solo actualizamos si no hay overflow
        if (uint256(number) + uint256(times) <= type(uint16).max) {
            valueIncrement += times;
            super.increment(times);
        }
    }

    function doble(uint16 a, uint16 b) public override {
        uint256 total = uint256(a) * uint256(b);
        if (total + number <= type(uint16).max) {
            valueDoble += uint16(total);
            super.doble(a, b);
        }
    }

    function echidna_no_overflow() public view returns (bool){
        return number <= type(uint16).max;
    }

    function echidna_setNumber() public returns (bool){
        setNumber(fuzzNumber);
        // Reseteamos shadow para mantener consistencia
        valueIncrement = fuzzNumber;
        valueDoble = 0;
        return number == fuzzNumber;
    }

    function echidna_increment() public returns (bool){
        return number == valueIncrement + valueDoble;
    }

    function echidna_doble() public returns (bool){
        return number == valueIncrement + valueDoble;
    }
/*
    // Variables controladas por Echidna
    uint8 private x;
    uint8 private times;
    uint8 private a;
    uint8 private b;

    uint256 constant MAX_GAS_SETNUMBER = 100000;
    uint256 constant MAX_GAS_INCREMENT = 180000;
    uint256 constant MAX_GAS_DOBLE = 180000;
    uint256 constant MAX_GAS_CALLDATA = 8000;

    // ===== Mutadores (Echidna los llama con inputs arbitrarios) =====

    function setX(uint8 _x) public {
        x = _x;
        setNumber(_x);
    }

    function setTimes(uint8 _times) public {
        times = _times;
    }

    function setA(uint8 _a) public {
        a = _a;
    }

    function setB(uint8 _b) public {
        b = _b;
    }

    function callIncrement() public {
        if (times > 50) return;
        if (uint256(number) + times > type(uint8).max) return;
        increment(times);
    }

    function callDoble() public {
        if (a > 50 || b > 50) return;
        if (uint256(number) + uint256(a) * uint256(b) > type(uint8).max) return;
        doble(a, b);
    }

    function callCalldata(
        uint256 a
    ) public {
        checkcalldata(a);
    }

    //-----

    function echidna_gas_setNumber() public returns (bool) {
        uint256 gasStart = gasleft();
        setNumber(number);
        uint256 gasUsed = gasStart - gasleft();
        return gasUsed <= MAX_GAS_SETNUMBER;
    }

    function echidna_gas_increment() public returns (bool) {
        uint256 gasStart = gasleft();
        callIncrement();
        uint256 gasUsed = gasStart - gasleft();
        return gasUsed <= MAX_GAS_INCREMENT;
    }

    function echidna_gas_doble() public returns (bool) {
        uint256 gasStart = gasleft();
        callDoble();
        uint256 gasUsed = gasStart - gasleft();
        return gasUsed <= MAX_GAS_DOBLE;
    }

    function echidna_gas_calldata() public returns (bool) {
        uint256 gasStart = gasleft();
        callCalldata(1);
        uint256 gasUsed = gasStart - gasleft();
        return gasUsed <= MAX_GAS_CALLDATA;
    }*/
}
