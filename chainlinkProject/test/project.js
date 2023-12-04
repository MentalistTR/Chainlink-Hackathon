const { expect } = require("chai");
const { ethers } = require("hardhat");
const provider = ethers.provider;

function ethToNum(val) {
  return Number(ethers.utils.formatEther(val));
}

async function getBlockTimestamp() {
  let block_number, block, block_timestamp;

  block_number = await provider.getBlockNumber();;
  block = await provider.getBlock(block_number);
  block_timestamp = block.timestamp;

  return block_timestamp;
}

async function increaseTime(value) {
  await provider.send('evm_increaseTime', [value]);
  await provider.send('evm_mine');
}

describe("Project Contract", function () {
  let Project, MentalToken;
  let project, mentalToken;
  let usdtProject, usdtToken;

  let owner;
  let addr1;
  const initialAmount = 100000000;

  let nameErc = "asd";
  let symbolErc =" ast";

  beforeEach(async function () {
    MentalToken = await ethers.getContractFactory("MentalToken");
    [owner, addr1] = await ethers.getSigners();

    usdtProject = await ethers.getContractFactory("TestUsdt");
    usdtToken = await usdtProject.deploy();

    Project = await ethers.getContractFactory("project");
    mentalToken = await MentalToken.deploy(initialAmount);

    project = await Project.deploy(4, mentalToken.address, usdtToken.address,nameErc ,symbolErc);

  
  });

  describe("Interest Rate Management", function () {
    it("Should allow only owner to update interest rate", async function () {
      await expect(project.updateInterestRate(10)).to.not.be.reverted;

      await expect(project.connect(addr1).updateInterestRate(10)).to.be.revertedWith("requirement failed");
    });

  });


  describe("depoist usdt", function () {

    const depositAmount = Number(10000);
    const depositAmoun2 = Number(1000);
    let balances;
    let reward;
    let balancesLast;


    beforeEach(async function () {

  
      await (usdtToken.mint(addr1.address, depositAmount));
      await usdtToken.connect(addr1).approve(project.address, Number(1000000000000));
      await project.connect(addr1).deposit_usdt(depositAmoun2);
      balances = await project.balances(addr1.address);

      increaseTime(18408206);
      reward = await (project.connect(addr1).calculateReward(addr1.address));

      await(project.connect(addr1).withdraw(depositAmoun2));
      balancesLast = await project.connect(addr1).balances(addr1.address);

    });

      it("user1 despoit 1000 usdt.", async function () {

        expect(balances).to.equal(1000);
  
      });

      it("user1 withdraw rewards", async function () {
      
        expect(reward).to.equal(2333);
      
      });

      it("user1 withdraw his usdt", async function () {

         expect(balancesLast).to.equal(0);

      });


  
  });

  



});
