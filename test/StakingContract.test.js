cat > test/StakingContract.test.js << 'ENDOFFILE'
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("StakingContract", function () {
  let token;
  let staking;
  let owner;
  let account2;
  let account3;

  beforeEach(async function () {
    [owner, account2, account3] = await ethers.getSigners();

    // Deploy token
    const CustomToken = await ethers.getContractFactory("CustomToken");
    token = await CustomToken.deploy("StakeToken", "STK", 1000000, owner.address);

    // Deploy staking contract
    const StakingContract = await ethers.getContractFactory("StakingContract");
    staking = await StakingContract.deploy(
      await token.getAddress(),
      await token.getAddress()
    );

    // Fund staking contract with rewards
    await token.approve(await staking.getAddress(), ethers.parseEther("500000"));
    await staking.fundRewards(ethers.parseEther("500000"));

    // Send tokens to account2
    await token.transfer(account2.address, ethers.parseEther("100000"));

    // Approve staking contract to spend account2 tokens
    await token.connect(account2).approve(await staking.getAddress(), ethers.parseEther("100000"));
  });

  // ── Deployment ──
  describe("Deployment", function () {
    it("Should set correct staking token", async function () {
      expect(await staking.stakingToken()).to.equal(await token.getAddress());
    });

    it("Should set correct reward rate", async function () {
      expect(await staking.rewardRate()).to.equal(20);
    });

    it("Should set correct lock period", async function () {
      expect(await staking.lockPeriod()).to.equal(30 * 24 * 60 * 60);
    });
  });

  // ── Staking ──
  describe("Staking", function () {
    it("Should allow user to stake tokens", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      expect(await staking.totalStaked()).to.equal(ethers.parseEther("10000"));
      const stakerInfo = await staking.stakers(account2.address);
      expect(stakerInfo.amount).to.equal(ethers.parseEther("10000"));
    });

    it("Should fail if staking 0 tokens", async function () {
      await expect(
        staking.connect(account2).stake(0)
      ).to.be.revertedWith("Cannot stake 0");
    });

    it("Should lock tokens after staking", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      expect(await staking.isLocked(account2.address)).to.equal(true);
    });
  });

  // ── Unstaking ──
  describe("Unstaking", function () {
    it("Should allow unstaking after lock period", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      await time.increase(30 * 24 * 60 * 60 + 1);
      await staking.connect(account2).unstake(ethers.parseEther("10000"));
      expect(await staking.totalStaked()).to.equal(0);
    });

    it("Should fail if unstaking before lock period", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      await expect(
        staking.connect(account2).unstake(ethers.parseEther("10000"))
      ).to.be.revertedWith("Tokens are still locked");
    });
  });

  // ── Rewards ──
  describe("Rewards", function () {
    it("Should accumulate rewards over time", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      await time.increase(365 * 24 * 60 * 60);
      const reward = await staking.calculateReward(account2.address);
      expect(reward).to.be.gt(0);
    });

    it("Should allow claiming rewards", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      await time.increase(365 * 24 * 60 * 60);
      await staking.connect(account2).claimReward();
      const stakerInfo = await staking.stakers(account2.address);
      expect(stakerInfo.lastClaimTime).to.be.gt(0);
    });
  });

  // ── Emergency Withdraw ──
  describe("Emergency Withdraw", function () {
    it("Should allow emergency withdraw", async function () {
      await staking.connect(account2).stake(ethers.parseEther("10000"));
      await staking.connect(account2).emergencyWithdraw();
      expect(await staking.totalStaked()).to.equal(0);
    });

    it("Should fail if nothing to withdraw", async function () {
      await expect(
        staking.connect(account2).emergencyWithdraw()
      ).to.be.revertedWith("Nothing to withdraw");
    });
  });

  // ── Owner Functions ──
  describe("Owner Functions", function () {
    it("Should allow owner to set reward rate", async function () {
      await staking.setRewardRate(50);
      expect(await staking.rewardRate()).to.equal(50);
    });

    it("Should allow owner to set lock period", async function () {
      await staking.setLockPeriod(60);
      expect(await staking.lockPeriod()).to.equal(60);
    });

    it("Should not allow non owner to set reward rate", async function () {
      await expect(
        staking.connect(account2).setRewardRate(50)
      ).to.be.reverted;
    });
  });
});
ENDOFFILE
