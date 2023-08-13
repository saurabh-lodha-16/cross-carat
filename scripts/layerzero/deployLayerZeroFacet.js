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
  const LayerZeroFacet = await hre.ethers.getContractFactory("LayerZeroFacet");
  const contractInstance = await LayerZeroFacet.deploy(
    config[hre.network.name]["layerzero"].helper
  );

  await contractInstance.deployed();
  console.log("LayerZeroFacet Contract deployed at:", contractInstance.address);

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/facets/LayerZeroFacet.sol:LayerZeroFacet",
    address: contractInstance.address,
    constructorArguments: [config[hre.network.name]["layerzero"].helper],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
