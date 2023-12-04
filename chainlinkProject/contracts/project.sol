// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MentalToken.sol";
import "./usdt.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract project is ERC20Pausable,ReentrancyGuard  {
    
    IERC20 public usdtToken;
    IERC20 public mentalToken;

    address public owner;
    uint256 public interestRate;
  

    mapping(address => uint256) public balances;

    mapping(address => uint256) public durations;

    mapping(address => uint256) public rewards;

    mapping(address => uint256) public initial;

    constructor(uint256 _interestRate, address _mentalToken, address _usdtToken,string memory name, string memory symbol)  ERC20(name, symbol){

        usdtToken = IERC20(_usdtToken);
        mentalToken = IERC20(_mentalToken);
        owner = msg.sender;
        interestRate = _interestRate;
    }

    event updateInterest(uint _interestrate);

    modifier updateReward(address _account) {
        rewards[_account] += calculateReward(_account);
        durations[_account] = block.timestamp;
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "requirement failed");
        _;
    }

    function calculateReward(address _account) public view returns (uint256) {
        uint256 duration = block.timestamp - durations[_account];
        return (balances[_account] * duration * 4) / 31556926;
    }

    function updateInterestRate(uint256 _interestrate) external onlyOwner {
        interestRate = _interestrate;
        emit updateInterest(_interestrate);
    }

    function deposit_usdt(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Invalid amount");
        initial[msg.sender] = block.timestamp;
        balances[msg.sender] += _amount;
        bool success = usdtToken.transferFrom(msg.sender, address(this), _amount);
        require(success,"Failed");
        emit updateInterest(_amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender)  whenNotPaused nonReentrant {
        require(initial[msg.sender] / 30 >= 180);
        require(_amount > 0, "Invalid amount");
        require(balances[msg.sender] >= _amount, "Invalid amount");
        balances[msg.sender] -= _amount;
        usdtToken.transfer(msg.sender, _amount);
        initial[msg.sender] = 0;
        emit updateInterest(_amount);
    }

    function withdraw_reward() external updateReward(msg.sender) whenNotPaused nonReentrant  {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "Invalid reward");
        rewards[msg.sender] = 0;
        mentalToken.transfer(msg.sender, reward);
       
    }

     function pause() internal virtual onlyOwner {
       _pause();
    }

     function unpause() internal virtual onlyOwner {
        _unpause();
    }
}
