/* global ethers */
/* eslint prefer-const: "off" */
const hre = require("hardhat");
const { ethers } = hre;

const { FacetCutAction } = require("./libraries/diamond.js");

async function addFacet() {
  const cut = [];

  const layerZeroFacet = await ethers.getContractAt(
    "LayerZeroFacet",
    "0xd13a389cE2130230Fbd919829fe2175B089ac3BC"
  );

  const hyperlaneFacet = await ethers.getContractAt(
    "HyperlaneFacet",
    "0xa683DB531AEE7968A89EaA396AFC5BEbFF885e27"
  );

  const ccipFacet = await ethers.getContractAt(
    "CCIPFacet",
    "0xAcE123E036Ff3355E6E3c392219e8f11ce303b00"
  );

  cut.push(
    {
      facetAddress: layerZeroFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: [
        layerZeroFacet.interface.getSighash(
          "useLayerZero(uint16,address,bytes,bytes,uint256)"
        ),
        layerZeroFacet.interface.getSighash(
          "layerZeroReceive(uint16,bytes,uint64,bytes)"
        ),
        layerZeroFacet.interface.getSighash("removeNativeToken()"),
      ],
    },
    {
      facetAddress: hyperlaneFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: [
        hyperlaneFacet.interface.getSighash(
          "useHyperlane(uint32,address,bytes,bytes,uint256)"
        ),
        hyperlaneFacet.interface.getSighash("handle(uint32,bytes32,bytes)"),
      ],
    },
    {
      facetAddress: ccipFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: [
        ccipFacet.interface.getSighash(
          "useCCIP(uint64,address,bytes,bytes,uint256)"
        ),
        ccipFacet.interface.getSighash(
          "ccipReceive((bytes32,uint64,bytes,bytes,(address,uint256)[]))"
        ),
      ],
    }
  );

  // upgrade diamond with facets
  console.log("");
  console.log("Diamond Cut:", cut);
  const diamondCut = await ethers.getContractAt(
    "IDiamondCut",
    "0x34fa80e9797163707775824105585aaD84336195"
  );
  let tx;
  let receipt;
  tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
  console.log("Diamond cut tx: ", tx.hash);
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  console.log("Completed diamond cut");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  addFacet()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.addFacet = addFacet;
