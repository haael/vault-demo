// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./IERC20.sol";

contract Vault is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply; // total WETH supply
    mapping(address => uint256) public balanceOf; // WETH balances
    mapping(address => mapping(address => uint256)) public allowance; // WETH allowances

    mapping(address => uint256) balanceOfETH; // ETH balances in this contract
    mapping(address => mapping(address => uint256)) balanceOfERC20; // ERC20 balances in this contract

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        // transfer WETH from sender to recipient
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        // approve transfer of WETH to spender
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool)
    {
        // transfer previously approved WETH
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        // create new WETH
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        // destroy WETH
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function deposit() public payable returns (bool) {
        // deposit ETH onto this contract
        balanceOfETH[msg.sender] += msg.value;
        return true;
    }

    function withdraw(uint256 amount) public returns (bool) {
        // withdraw ETH from this contract
        balanceOfETH[msg.sender] -= amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw ETH.");
        return true;
    }

    function wrap(uint256 amount) public returns (bool) {
        // convert ETH balance into WETH balance
        balanceOfETH[msg.sender] -= amount;
        _mint(msg.sender, amount);
        return true;
    }

    function unwrap(uint256 amount) public returns (bool) {
        // convert WETH balance into ETH balance
        _burn(msg.sender, amount);
        balanceOfETH[msg.sender] += amount;
        return true;
    }

    function depositToken(address token, uint256 amount) public returns (bool) {
        // deposit previously approved ERC20 token onto the vault
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transferFrom(msg.sender, address(this), amount); // transfer from sender to this contract
        require(success, "Could not transfer ERC20 from other address to this contract.");
        balanceOfERC20[msg.sender][token] += amount; // credit sender
        return true;
    }

    function withdrawToken(address token, uint256 amount) public returns (bool) {
        // withdraw ERC20 token to sender's address
        balanceOfERC20[msg.sender][token] -= amount; // reduce sender's balance
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transfer(msg.sender, amount); // transfer from this contract to sender
        require(success, "Could not transfer ERC20 from this contract to other address.");
        return true;
    }
}
