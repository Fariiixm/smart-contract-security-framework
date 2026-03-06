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

        if(times > type(uint16).max){
            vm.expectRevert(bytes("Overflow"));
            counter.increment(times);
        }else{
            counter.increment(times);
            assertEq(counter.number(), times);
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


        // Evitamos el overflow (pánico 0x11) limitando los inputs para este test
        // ya que Counter.sol usa aritmética chequeada (Solidity 0.8+)
        vm.assume(uint16(a) * uint16(b) < 256);

        counter.setNumber(0);

        // We use a larger type for calculation to avoid overflow in test expectation
        uint256 expected = uint256(a) * uint256(b);

        // Since number is uint8, it will wrap
        uint8 expectedWrapped = uint8(expected % 256);

        counter.doble(a, b);
        assertEq(counter.number(), expectedWrapped);
    }
}
