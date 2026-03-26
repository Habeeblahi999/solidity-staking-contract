// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomToken is ERC20, Ownable {
    uint256 public burnFee = 200;
    uint256 public taxFee = 300;
    uint256 public constant MAX_FEE = 1000;
    address public taxWallet;
    mapping(address => bool) public isExcludedFromFee;

    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address taxWallet_) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(taxWallet_ != address(0), "Invalid tax wallet");
        taxWallet = taxWallet_;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from == address(0) || to == address(0) || isExcludedFromFee[from] || isExcludedFromFee[to]) {
            super._update(from, to, amount);
            return;
        }
        uint256 burnAmount = (amount * burnFee) / 10000;
        uint256 taxAmount = (amount * taxFee) / 10000;
        uint256 sendAmount = amount - burnAmount - taxAmount;
        if (taxAmount > 0) super._update(from, taxWallet, taxAmount);
        if (burnAmount > 0) super._update(from, address(0), burnAmount);
        super._update(from, to, sendAmount);
    }

    function mint(address to, uint256 amount) external onlyOwner { _mint(to, amount); }
    function setBurnFee(uint256 newFee) external onlyOwner { require(newFee + taxFee <= MAX_FEE, "Too high"); burnFee = newFee; }
    function setTaxFee(uint256 newFee) external onlyOwner { require(burnFee + newFee <= MAX_FEE, "Too high"); taxFee = newFee; }
    function setTaxWallet(address newWallet) external onlyOwner { require(newWallet != address(0), "Invalid"); taxWallet = newWallet; }
    function setExcludedFromFee(address account, bool excluded) external onlyOwner { isExcludedFromFee[account] = excluded; }
}
