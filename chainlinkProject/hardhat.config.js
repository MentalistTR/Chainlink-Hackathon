require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.22",
  
  hardhat: {
    gas:200000000000000,
    gasPrice: 20000000000000,
  },

};