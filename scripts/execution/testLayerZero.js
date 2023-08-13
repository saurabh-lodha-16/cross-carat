/* eslint-disable no-process-exit */
const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const abiCoder = new hre.ethers.utils.AbiCoder();

  //Update below variable with value you want to update on remote chain. (For testing the flow)
  const valueToUpdate = 169;
  const sendAcknowledgment = true;

  //build destination chain contract execution calldata
  const ABI = ["function store(uint8 _num)"];
  let iface = new hre.ethers.utils.Interface(ABI);
  const contractCalldata = iface.encodeFunctionData("store", [valueToUpdate]);

  const destinationChainContract = "0x6040e9F331A407e219524852C24dACd2B2343135";
  const bridgeSelector = 0; //Layerzero
  const srcChainID = 420; //optimism
  const destChainID = 80001; //polygon

  //build bridge params
  const bridgeParams = abiCoder.encode(
    ["address", "address", "uint256", "bytes"],
    [
      "0x10855704d1Dde09d90C0D1afEe4E1e6626e45Bb7", //source chain refund address
      "0x10855704d1Dde09d90C0D1afEe4E1e6626e45Bb7", //destination chain refund address
      ethers.utils.parseEther("6"), //relayer fees to be used on destination chain
      ethers.utils.solidityPack(["uint16", "uint256"], [1, 600000]), //gas limit for tx on destination chain
    ]
  );

  const sourceChainMockContract = await ethers.getContractAt(
    "SourceChainMock",
    "0x16ca587acc63deBE6651E6793620eb818e4359DB"
  );

  //Executing CrossChain Transaction through SourceChainMock Contract and API
  const tx = await sourceChainMockContract.storeOnRemote(
    sendAcknowledgment,
    contractCalldata,
    destinationChainContract,
    bridgeSelector,
    srcChainID,
    destChainID,
    bridgeParams,
    sourceChainMockContract.address,
    {
      value: ethers.utils.parseEther("0.1"),
    }
  );

  console.log("Cross Chain tx: ", tx.hash);
  const receipt = await tx.wait();
  console.log("Completed source cross chain transaction");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
