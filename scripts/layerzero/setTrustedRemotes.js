/* eslint-disable no-process-exit */
const hre = require("hardhat");
require("dotenv").config();

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  // We get the contract to deploy

  const LayerZeroHelper = await hre.ethers.getContractFactory(
    "LayerZeroHelper"
  );

  const layerZeroHelperPolygonMumbai =
    "0x6eA0C1BF680DBb8003c66d545a0D228285Bb2491";
  const layerZeroHelperOptimismGoerli =
    "0xd13a389cE2130230Fbd919829fe2175B089ac3BC";
  const layerZeroHelperBaseGoerli =
    "0x69D5F6D9EdE8F74Fa1D0245144Bd9628D3115394";

  const contractInstancePolygonMumbai = LayerZeroHelper.attach(
    layerZeroHelperPolygonMumbai
  );

  const contractInstanceOptimismGoerli = LayerZeroHelper.attach(
    layerZeroHelperOptimismGoerli
  );

  const contractInstanceBaseGoerli = LayerZeroHelper.attach(
    layerZeroHelperBaseGoerli
  );

  //set trusted remote polygon Mumbai

  const tx1 = await contractInstanceOptimismGoerli.setTrustedRemote(
    10109,
    ethers.utils.solidityPack(
      ["address", "address"],
      [
        contractInstancePolygonMumbai.address,
        contractInstanceOptimismGoerli.address,
      ]
    )
  );

  console.log(tx1.hash);

  await sleep(30000);

  const tx2 = await contractInstanceOptimismGoerli.setTrustedRemote(
    10160,
    ethers.utils.solidityPack(
      ["address", "address"],
      [
        contractInstanceBaseGoerli.address,
        contractInstanceOptimismGoerli.address,
      ]
    )
  );

  console.log(tx2.hash);

  await sleep(30000);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
