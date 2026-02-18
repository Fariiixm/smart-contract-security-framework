// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Counter.sol";

contract EchidnaCounterTest is Counter {

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
        uint16 a1, uint16 b1, uint16 c1, uint16 d1,
        uint16 e1, uint16 f1, uint16 g1, uint16 h1
    ) public {
        checkcalldata(a1, b1, c1, d1, e1, f1, g1, h1);
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
        callCalldata(1,2,3,4,5,6,7,8);
        uint256 gasUsed = gasStart - gasleft();
        return gasUsed <= MAX_GAS_CALLDATA;
    }
}
