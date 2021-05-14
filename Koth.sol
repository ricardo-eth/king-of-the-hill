// SPDX-License-Identifier: MIT

import "./Ownable.sol";

pragma solidity ^0.8.0;

contract Koth is Ownable {
    
    // State variables
    address private _winner;
    mapping(address => uint256) private _userBalances;
    uint256 private _tax;
    uint256 private _pot;
    uint256 private _baseBlocks;
    uint256 private _blocks;
    
    // Events
    event Deposit(address indexed account, uint256 amount);
    
    // Constructor
    constructor(address owner_, uint256 tax_, uint256 pot_, uint256 howManyBlocks_) Ownable(owner_) payable {
        require(tax_ >= 0 && tax_ <= 100, "Koth: Invalid percentage");
        require(pot_ >= 0, "Koth: minimium balance require");
        _baseBlocks = howManyBlocks_;
        _blocks = block.number + _baseBlocks;
        _winner = msg.sender;
        _tax = tax_; 
        _pot = pot_;
    }
    
    // Modifiers
    modifier potStart(){
        require(msg.value >= 1e9,"Koth: send more than 1gwei");
        _;
    }
    
    modifier depositDouble(){
        require(msg.value >= _pot * 2,"Koth: send the double of the actual balance");
        _;
    }
    
    // Function declarations
    function deposit() public payable potStart depositDouble {
        emit Deposit(msg.sender, msg.value);
        _winner = msg.sender;
        uint256 amount = msg.value - _pot * 2;
        if (amount > 0) payable(msg.sender).transfer(amount);
        _pot += msg.value - amount;
    }
    
    function pot() public view returns (uint256) {
        return _pot;
    }
    
    function balance() public view returns (uint256) {
        return _userBalances[msg.sender];
    }
    
    function tax() public view returns (uint256) {
        return _tax;
    }
    
    function winner() public view returns (address) {
        return _winner;
    }
    
}