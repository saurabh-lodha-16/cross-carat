/* eslint-disable no-process-exit */
require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs").promises;
const config = require("../config.json");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  const LayerZeroHelper = await hre.ethers.getContractFactory(
    "LayerZeroHelper"
  );

  const contractInstance = await LayerZeroHelper.deploy(
    config[hre.network.name]["layerzero"].endpoint,
    config[hre.network.name]["layerzero"].diamond
  );

  await contractInstance.deployed();
  console.log(
    "LayerZeroHelper Contract deployed at:",
    contractInstance.address
  );

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/LayerZeroHelper.sol:LayerZeroHelper",
    address: contractInstance.address,
    constructorArguments: [
      config[hre.network.name]["layerzero"].endpoint,
      config[hre.network.name]["layerzero"].diamond,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
