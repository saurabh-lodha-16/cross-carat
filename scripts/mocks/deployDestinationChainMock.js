/* eslint-disable no-process-exit */
const hre = require("hardhat");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  // We get the contract to deploy
  const DestinationChainMock = await hre.ethers.getContractFactory(
    "DestinationChainMock"
  );
  const contractInstance = await DestinationChainMock.deploy();

  await contractInstance.deployed();
  console.log(
    "DestinationChainMock Contract deployed at:",
    contractInstance.address
  );

  await sleep(30000);

  await hre.run("verify:verify", {
    contract: "contracts/mocks/DestinationChainMock.sol:DestinationChainMock",
    address: contractInstance.address,
    constructorArguments: [],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
