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
  const SourceChainMock = await hre.ethers.getContractFactory(
    "SourceChainMock"
  );
  const contractInstance = await SourceChainMock.deploy(
    config[hre.network.name]["wrapper"]
  );

  await contractInstance.deployed();
  console.log(
    "SourceChainMock Contract deployed at:",
    contractInstance.address
  );

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/mocks/SourceChainMock.sol:SourceChainMock",
    address: contractInstance.address,
    constructorArguments: [config[hre.network.name]["wrapper"]],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
