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
  const CCIPFacet = await hre.ethers.getContractFactory("CCIPFacet");
  const contractInstance = await CCIPFacet.deploy(
    config[hre.network.name]["ccip"].router
  );

  await contractInstance.deployed();
  console.log("CCIPFacet Contract deployed at:", contractInstance.address);

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/facets/CCIPFacet.sol:CCIPFacet",
    address: contractInstance.address,
    constructorArguments: [config[hre.network.name]["ccip"].router],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
