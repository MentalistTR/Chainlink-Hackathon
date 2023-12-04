const { expect } = require("chai");
const { ethers } = require("hardhat");
const provider = ethers.provider;

function ethToNum(val) {
  return Number(ethers.utils.formatEther(val));
}

async function increaseTime(value) {
  await provider.send('evm_increaseTime', [value]);
  await provider.send('evm_mine');
}

describe("MentalToken Contract", function () {
  let MentalToken;
  let mentalToken;
  let owner;
  const initialAmount = 100000000;

  beforeEach(async function () {
    // MentalToken sözleşmesi için ayarlar
    MentalToken = await ethers.getContractFactory("MentalToken");
    [owner] = await ethers.getSigners();
    mentalToken = await MentalToken.deploy(initialAmount);
  });

  describe("Total Supply", function () {
    it("should return the correct total supply", async function () {
      // totalSupply fonksiyonunun doğru değeri döndürdüğünü kontrol et
      expect(await mentalToken.totalSupply()).to.equal(initialAmount);
    });

    it("is Name Correct", async () => {
      expect(await mentalToken.name()).to.equal("Mentality");
    });

    it("is Symbol Correct", async () => {
      expect(await mentalToken.symbol()).to.equal("MTL");
    });

    it("is Initial Supply Correct", async () => {
      expect(await mentalToken.totalSupply()).to.equal(initialAmount);
    });

    it("is Decimal Zero", async () => {
      expect(await mentalToken.decimals()).to.equal(Number(18));
    });

 
  });


});
