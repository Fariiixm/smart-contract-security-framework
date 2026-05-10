// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../contracts/Counter.sol";

contract EchidnaGasCounterTest is Counter {
    uint256 constant MAX_GAS_SETNUMBER = 100000;
    uint256 constant MAX_GAS_INCREMENT = 1800000;
    uint256 constant MAX_GAS_DOUBLE = 10000000;
    
    function testGasSetNumber(uint16 num) public {
        uint256 gasStart = gasleft();
        setNumber(num);
        uint256 gasUsed = gasStart - gasleft();
        assert(gasUsed <= MAX_GAS_SETNUMBER);
    }

    function testGasIncrement(uint16 num, uint16 times) public {
        setNumber(num);
        require(num + times <= type(uint16).max);

        uint256 gasStart = gasleft();
        increment(times);
        uint256 gasUsed = gasStart - gasleft();

        assert(gasUsed <= MAX_GAS_INCREMENT);
    }

    function testGasDouble(uint16 num, uint16 a, uint16 b) public {
        setNumber(num);

        uint256 total = uint256(num) + uint256(a) * uint256(a);

        require(total <= type(uint16).max);

        uint256 gasStart = gasleft();
        double(a, b);
        uint256 gasUsed = gasStart - gasleft();

        assert(gasUsed <= MAX_GAS_DOUBLE);
    }

    function testGasCalldata() public {
        checkcalldata(0);
        uint256 gas1 = gasleft();
        checkcalldata(0);
        uint256 gas2 = gasleft();

        checkcalldata(1);
        uint256 gas3 = gasleft();

        uint256 gasUsed1 = gas1 - gas2;
        uint256 gasUsed2 = gas2 - gas3;

        assert(gasUsed1 < 38);
        //assert(gasUsed2 < 39);
    }
}