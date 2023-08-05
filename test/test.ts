import { parseEther } from "ethers/lib/utils";
import { artifacts, contract } from "hardhat";
import { assert, expect } from "chai";
import {
  BN,
  constants,
  expectEvent,
  expectRevert,
  time,
} from "@openzeppelin/test-helpers";

const MockERC20 = artifacts.require("./utils/MockERC20.sol");
const MockRandomNumberGenerator = artifacts.require(
  "./utils/MockRandomNumberGenerator.sol"
);
const PancakeSwapLottery = artifacts.require("./PancakeSwapLottery.sol");

const PRICE_BNB = 400;

function gasToBNB(gas: number, gwei: number = 5) {
  const num = gas * gwei * 10 ** -9;
  return num.toFixed(4);
}

function gasToUSD(gas: number, gwei: number = 5, priceBNB: number = PRICE_BNB) {
  const num = gas * priceBNB * gwei * 10 ** -9;
  return num.toFixed(2);
}

contract(
  "Lottery V2",
  ([alice, bob, carol, david, erin, operator, treasury, injector]) => {
    // VARIABLES
    const _totalInitSupply = parseEther("10000");

    let _lengthLottery = new BN("14400"); // 4h
    let _priceTicketInCake = parseEther("0.5");
    let _discountDivisor = "2000";

    let _rewardsBreakdown = ["200", "300", "500", "1500", "2500", "5000"];
    let _treasuryFee = "2000";

    // Contracts
    let lottery, mockCake, randomNumberGenerator;

    // Generic variables
    let result: any;
    let endTime;

    before(async () => {
      // Deploy MockCake
      mockCake = await MockERC20.new("Mock CAKE", "CAKE", _totalInitSupply);

      // Deploy MockRandomNumberGenerator
      randomNumberGenerator = await MockRandomNumberGenerator.new({
        from: alice,
      });

      // Deploy PancakeSwapLottery
      lottery = await PancakeSwapLottery.new(
        mockCake.address,
        randomNumberGenerator.address,
        { from: alice }
      );

      await randomNumberGenerator.setLotteryAddress(lottery.address, {
        from: alice,
      });
    });
  }
);
