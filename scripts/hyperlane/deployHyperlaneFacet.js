/* eslint-disable no-process-exit */
const hre = require("hardhat");
const config = require("../config.json");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  // We get the contract to deploy
  const HyperlaneFacet = await hre.ethers.getContractFactory("HyperlaneFacet");
  const contractInstance = await HyperlaneFacet.deploy(
    config[hre.network.name]["hyperlane"].mailbox,
    config[hre.network.name]["hyperlane"].interchainGasPaymaster
  );

  await contractInstance.deployed();
  console.log("HyperlaneFacet Contract deployed at:", contractInstance.address);

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/facets/HyperlaneFacet.sol:HyperlaneFacet",
    address: contractInstance.address,
    constructorArguments: [
      config[hre.network.name]["hyperlane"].mailbox,
      config[hre.network.name]["hyperlane"].interchainGasPaymaster,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
