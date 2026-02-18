// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract CalldataGas {
    function f(uint256 x) public pure {
        // Does nothing, just to measure calldata cost
    }
}
