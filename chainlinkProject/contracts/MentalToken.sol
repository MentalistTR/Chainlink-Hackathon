// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MentalToken is ERC20 {

    uint256 public _totalSupply;
   

    constructor(uint256 _amount) ERC20("Mentality", "MTL") {
        _totalSupply = _amount;
        _mint(address(this), _amount);
    }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
}
}
