/* eslint-disable no-process-exit */
const hre = require("hardhat");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  // We get the contract to deploy
  const Wrapper = await hre.ethers.getContractFactory("Wrapper");
  const contractInstance = await Wrapper.deploy();

  await contractInstance.deployed();
  console.log("Wrapper Contract deployed at:", contractInstance.address);

  await sleep(15000);

  // await hre.run("verify:verify", {
  //   contract: "contracts/Wrapper.sol:Wrapper",
  //   address: contractInstance.address,
  //   constructorArguments: [],
  // });

  await contractInstance.upsertChainIDToDiamondContract(
    [80001, 420, 84531],
    [
      "0xD1FaE79D5836d6A8456AE8B081A7053d91157A03",
      "0x6537f4f568159B7b42E7878915b1f104b91a9951",
      "0x34fa80e9797163707775824105585aaD84336195",
    ]
  );

  await sleep(15000);

  await contractInstance.upsertChainIDToLayerZeroChainID(
    [80001, 420, 84531],
    [10109, 10132, 10160]
  );

  await sleep(15000);

  await contractInstance.upsertChainIDToHyperlaneDomainID(
    [80001, 420],
    [80001, 420]
  );

  await sleep(15000);

  await contractInstance.upsertChainIDToCCIPChainSelector(
    [80001, 420],
    ["12532609583862916517", "2664363617261496610"]
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
