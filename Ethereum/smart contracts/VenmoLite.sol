pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2;

contract Venmo {
    struct Payment {
        address receiver;
        uint256 amount; // in Wei; 1 Ether = 10^18 Wei
    }
    event Pay(address, address, uint256);
    mapping (address => Payment[] ) payments;
    Payment[] allPayments;
    function pay(address receiver) public payable { // 1 Ether = 10^18 wei
        require(msg.sender != receiver, "sender and receiver are same");
        // transfer TO receiver
        receiver.transfer(msg.value);
        // create a new payment
        Venmo.Payment memory p = Payment(receiver, msg.value);
        // add payment to the set of payments from this sender
        payments[msg.sender].push(p);
        // add payment to the list of all payments
        allPayments.push(p);
        // Generate an event for the payment
        emit Pay(msg.sender, receiver, msg.value);
    }
    function getPaymentsFromAddress(address a) public view returns(Payment[] memory) {
        return payments[a];
    }
    function getMyPayments() public view returns (Payment[] memory) {
        return payments[msg.sender];
    }
    function getAllPayments() public view returns(Payment[] memory) {
        return allPayments;
    }
}