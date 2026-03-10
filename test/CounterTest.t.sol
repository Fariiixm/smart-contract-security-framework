// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function testSetNumber(uint16 num) public {
        counter.setNumber(num);
        assertEq(counter.number(), num);
    }

    function testIncrement(uint16 num, uint16 times) public {
        counter.setNumber(num);

        if(uint256(num) + uint256(times) > type(uint16).max){
            vm.expectRevert(bytes("Overflow"));
            counter.increment(times);
        }else{
            counter.increment(times);
            assertEq(counter.number(), num + times);
        }
    }

    function testDoble(uint16 num, uint16 a, uint16 b) public {
        counter.setNumber(num);

        uint256 mult = uint256(a) * uint256(b);

        if(mult > type(uint16).max){
            vm.expectRevert(bytes("Overflow"));
            counter.doble(a, b);
        }else if(uint256(num) + mult > type(uint16).max){
            vm.expectRevert(bytes("Overflow"));
            counter.doble(a, b);
        }else{
            counter.doble(a, b);
            assertEq(counter.number(), uint16(num + mult));
        }
    }
}
