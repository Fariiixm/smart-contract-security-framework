// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function testSetNumber(uint8 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testIncrement(uint8 times) public {
        counter.setNumber(0);
        counter.increment(times);
        assertEq(counter.number(), times);
    }

    function testDoble(uint8 a, uint8 b) public {
        // Evitamos el overflow (pánico 0x11) limitando los inputs para este test
        // ya que Counter.sol usa aritmética chequeada (Solidity 0.8+)
        vm.assume(uint256(a) * uint256(b) < 256);

        counter.setNumber(0);

        // We use a larger type for calculation to avoid overflow in test expectation
        uint256 expected = uint256(a) * uint256(b);

        // Since number is uint8, it will wrap
        uint8 expectedWrapped = uint8(expected % 256);

        counter.doble(a, b);
        assertEq(counter.number(), expectedWrapped);
    }
}
