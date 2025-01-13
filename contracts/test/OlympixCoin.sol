// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OlympixCoin is ERC20 {
    address public treasury;
    address public owner;
    bool public taxEnabled;
    constructor(
        address _treasury,
        address _owner
    ) ERC20("OlympixCoin", "OLX") {
        require(_treasury != address(0), "Treasury address cannot be zero");
        require(_owner != address(0), "Owner address cannot be zero");
        owner = _owner;
        treasury = _treasury;
        taxEnabled = true;
        _mint(msg.sender, 150000);
        _mint(treasury, 350000);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Recipient address cannot be zero");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (taxEnabled) {
            uint256 tax = 2;
            uint256 taxedAmount = amount - tax;
            _transfer(_msgSender(), treasury, tax);
            _transfer(_msgSender(), recipient, taxedAmount);
            return true;
        } else {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    }

    function toggleTax(bool _taxEnabled) public {
        require(msg.sender == owner, "Only owner can set taxEnabled");
        require(_taxEnabled == true || _taxEnabled == false, "Invalid taxEnabled value");
        taxEnabled = _taxEnabled;
    }

    
}