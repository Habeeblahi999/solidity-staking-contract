// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingContract is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate = 20;
    uint256 public lockPeriod = 30 days;
    uint256 public totalStaked;

    struct Staker {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 lockEndTime;
    }

    mapping(address => Staker) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address stakingToken_, address rewardToken_) Ownable(msg.sender) {
        stakingToken = IERC20(stakingToken_);
        rewardToken = IERC20(rewardToken_);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            uint256 pending = calculateReward(msg.sender);
            if (pending > 0) { rewardToken.transfer(msg.sender, pending); emit RewardClaimed(msg.sender, pending); }
        }
        staker.amount += amount;
        staker.startTime = block.timestamp;
        staker.lastClaimTime = block.timestamp;
        staker.lockEndTime = block.timestamp + lockPeriod;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount >= amount, "Insufficient staked amount");
        require(block.timestamp >= staker.lockEndTime, "Tokens are still locked");
        uint256 pending = calculateReward(msg.sender);
        if (pending > 0) { rewardToken.transfer(msg.sender, pending); emit RewardClaimed(msg.sender, pending); }
        staker.amount -= amount;
        staker.lastClaimTime = block.timestamp;
        totalStaked -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external nonReentrant {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");
        stakers[msg.sender].lastClaimTime = block.timestamp;
        require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    function emergencyWithdraw() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount > 0, "Nothing to withdraw");
        uint256 amount = staker.amount;
        staker.amount = 0;
        staker.lastClaimTime = block.timestamp;
        totalStaked -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function calculateReward(address user) public view returns (uint256) {
        Staker memory staker = stakers[user];
        if (staker.amount == 0) return 0;
        uint256 timeElapsed = block.timestamp - staker.lastClaimTime;
        return (staker.amount * rewardRate * timeElapsed) / (100 * 365 days);
    }

    function isLocked(address user) public view returns (bool) { return block.timestamp < stakers[user].lockEndTime; }
    function timeUntilUnlock(address user) public view returns (uint256) {
        if (block.timestamp >= stakers[user].lockEndTime) return 0;
        return stakers[user].lockEndTime - block.timestamp;
    }
    function setRewardRate(uint256 newRate) external onlyOwner { require(newRate > 0 && newRate <= 1000, "Invalid rate"); rewardRate = newRate; }
    function setLockPeriod(uint256 newPeriod) external onlyOwner { lockPeriod = newPeriod; }
    function fundRewards(uint256 amount) external onlyOwner { require(rewardToken.transferFrom(msg.sender, address(this), amount), "Transfer failed"); }
    function rewardBalance() external view returns (uint256) { return rewardToken.balanceOf(address(this)); }
}
