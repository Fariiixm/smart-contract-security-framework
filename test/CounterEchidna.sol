// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Counter.sol";

contract CounterEchidnaTest is Counter{

    function testSetNumber(uint16 num) public{
        setNumber(num);
        assert(number == num);
    }

    function testIncrement(uint16 num, uint16 times) public{
        setNumber(num);
        increment(times);

        assert(number == num + times);
    }

    function testDouble(uint16 num, uint16 a, uint16 b) public{
        uint256 total = uint256(a) * uint256(b);
        

        setNumber(num);
        double(a, b);

        assert(number == num + uint16(total));
    }
}