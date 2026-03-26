# Solidity Staking Contract

A production-ready ERC-20 token staking contract built with 
Solidity and OpenZeppelin, deployed on the Ethereum Sepolia testnet.

## Features
- 🏦 Stake ERC-20 tokens and earn rewards
- 💰 20% APY reward rate
- 🔒 30 day lock period
- 🎁 Claim rewards anytime
- 🚨 Emergency withdraw mechanism
- ⚙️ Owner adjustable reward rate and lock period
- 🛡️ ReentrancyGuard protection

## Tech Stack
- Solidity 0.8.26
- OpenZeppelin Contracts
- Hardhat
- Ethers.js
- Ethereum Sepolia Testnet

## Contract Details
- **Network:** Ethereum Sepolia Testnet
- **StakeToken:** 0xFD5C5e323Ec4112DDa0937C4c6F961E7F4E65e19
- **StakingContract:** 0x78c36b4c3eB37D1c4d05A9c3847e6176D3d05D57

## Live Contracts
- StakeToken on Etherscan:
https://sepolia.etherscan.io/address/0xFD5C5e323Ec4112DDa0937C4c6F961E7F4E65e19
- StakingContract on Etherscan:
https://sepolia.etherscan.io/address/0x78c36b4c3eB37D1c4d05A9c3847e6176D3d05D57

## How It Works
1. Owner funds the contract with reward tokens
2. Users approve the staking contract to spend their tokens
3. Users stake tokens and start earning rewards
4. Rewards accumulate every second based on APY
5. Users can claim rewards anytime
6. Users can unstake after the lock period ends
7. Emergency withdraw available anytime (forfeits rewards)

## Functions
| Function | Description |
|---|---|
| `stake` | Stake tokens and start earning |
| `unstake` | Withdraw tokens after lock period |
| `claimReward` | Claim accumulated rewards |
| `emergencyWithdraw` | Withdraw tokens instantly (no rewards) |
| `calculateReward` | Check pending rewards |
| `isLocked` | Check if tokens are locked |
| `timeUntilUnlock` | Check remaining lock time |
| `setRewardRate` | Owner can adjust APY |
| `setLockPeriod` | Owner can adjust lock period |
| `fundRewards` | Owner funds reward pool |

## Test Results
```
15 passing ✅
```

## License
MIT
