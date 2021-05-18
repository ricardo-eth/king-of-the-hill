// SPDX-License-Identifier: MIT

/*
  _  ___                      __   _   _            _    _ _ _ _ 
 | |/ (_)                    / _| | | | |          | |  | (_) | |
 | ' / _ _ __   __ _    ___ | |_  | |_| |__   ___  | |__| |_| | |
 |  < | | '_ \ / _` |  / _ \|  _| | __| '_ \ / _ \ |  __  | | | |
 | . \| | | | | (_| | | (_) | |   | |_| | | |  __/ | |  | | | | |
 |_|\_\_|_| |_|\__, |  \___/|_|    \__|_| |_|\___| |_|  |_|_|_|_|
                __/ |                                            
               |___/                                             

Repo: https://github.com/ricardo-eth/king-of-the-hill

 * * 
 *
 * @title: KingOfTheHill
 * @author: ricardo-eth
 * @rules: The owner initiates an amount, then players must pay double the amount and wait for XX blocks defined by the creator to win.
 * @notice The owner must initiate the pot at 1 gwei or more (constructor).
 * 
 * *
*/

pragma solidity ^0.8.0;

contract Koth {
    
    // @dev state variables
    mapping(address => uint256) private _userBalances;
    uint256 private _blocks;
    uint256 private _base;
    uint256 private _pot;
    address private _owner;
    address private _winner;
    uint256 private _tax;
    uint256 private _seedRest;

    // @dev events
    event Deposit(address indexed account, uint256 amount);
    event Withdrew(address indexed account, uint256 amount);
    event TimeReach(address indexed winner, uint256 amount);

    /**
      * @dev There are 1 important constructor : 
      * - contractOwner_ : owner of the contract.
      * - blocks_ : set the number of blocks before winning.
      * - tax_ : percentage of the tax for the owner.
      * - seedRestNextRound_ : percentage of what is left in the pot for the new round.
     **/
     
    constructor(address contractOwner_, uint256 blocks_, uint256 tax_, uint256 seedRestNextRound_) payable {
        require(msg.value >= 1e9, "Koth: The owner must initiate the pot at 1gwei or more");
        require(tax_ >= 0 && tax_ <= 15, "Koth: Invalid percentage");
        require(seedRestNextRound_ >= 0 && seedRestNextRound_ <= 15, "Koth: Invalid percentage");
        _blocks = block.number + blocks_;
        _base = blocks_;
        _owner = contractOwner_;
        _winner = msg.sender;
        _pot = msg.value;
        _tax = tax_;
        _seedRest = seedRestNextRound_;
    }

    // @dev modifiers
    modifier onlyContractOwner() {
        require(msg.sender == _owner, "Koth: Only contract owner can call this function.");
        _;
    }
    modifier ownerCantPlay() {
        require(msg.sender != _owner, "Koth: owner can not play");
        _;
    }
    modifier depositDouble() {
        require(msg.value >= _pot * 2, "Koth: send the double of the actual on the pot");
        _;
    }
    
    modifier withdrawZero() {
         require(_userBalances[msg.sender] > 0, "Koth: can not withdraw 0 ether");
        _;
    }
    
    // @dev functions
    function deposit() public payable depositDouble ownerCantPlay{
        emit Deposit(msg.sender, msg.value);
        _blocks = block.number + _base;
        _winner = msg.sender;
        uint256 rest = msg.value - _pot * 2;
        if (rest > 0) payable(msg.sender).transfer(rest);
        _pot += msg.value - rest;
    }

    function withdraw() public {
        uint256 amount = _userBalances[msg.sender];
        emit Withdrew(msg.sender, amount);
        _userBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function _timeReached() private {
        if (block.number >= _blocks) {
            uint256 _allTax = _tax + _seedRest;
            emit TimeReach(_winner, _pot * (100 - _allTax) / 100);
            _userBalances[_winner] = _pot * (100 - _allTax) / 100;
            _userBalances[_owner] = _pot * (100 - _tax) / 100;
            _pot = _seedRest / 100;
            _blocks = block.number + _base;
        }
    }

    function withdrawall() public onlyContractOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // @dev getters
    function getPot() public view returns (uint256) {
        return _pot;
    }

    function getBalance() public view returns (uint256) {
        return _userBalances[msg.sender];
    }

    function getWinner() public view returns (address) {
        return _winner;
    }

    function getBlocks() public view returns (uint256) {
        return _blocks;
    }

    function getBlocknumber() public view returns (uint256) {
        return block.number;
    }
}