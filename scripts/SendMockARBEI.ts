import { ethers } from "hardhat";
import {
    abi as Factory_ABI,
    bytecode as Factory_BYTECODE,
  } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import { IndexFactory } from "../typechain-types";
import { goerliAnfiFactoryAddress, sepoliaAnfiFactoryAddress, sepoliaBitcoinAddress, sepoliaXautAddress, sepoliaTestArbitrumAddress, sepoliaTestChainLinkAddress, sepoliaTestUniswapAddress, sepoliaTestMakerAddress, sepoliaTestGraphAddress, sepoliaTestGnosisAddress, sepoliaTestLidoAddress, sepoliaTestWOOAddress, sepoliaTestCurveAddress, sepoliaTestCOMPAddress, sepoliaTestFroxSharesAddress, sepoliaSCIFactoryAddress, sepoliaTestAAVEAddress, sepoliaTestCLIPPERAddress, sepoliaTestPENDLEAddress, sepoliaTestSILOAddress, sepoliaTestCAKEAddress, sepoliaTestDODOAddress, sepoliaTestSALEAddress, sepoliaTestPNPAddress, sepoliaTestCVXAddress, sepoliaTestJOEAddress, sepoliaARBEIIndexFactoryAddress } from "../contractAddresses";
// import { sepoliaTestArbitrumAddress, sepoliaTestChainLinkAddress, sepoliaTestUniswapAddress, sepoliaTestMakerAddress, sepoliaTestGraphAddress, sepoliaTestGnosisAddress, sepoliaTestLidoAddress, sepoliaTestWOOAddress, sepoliaTestCurveAddress, sepoliaTestCOMPAddress, sepoliaTestFroxSharesAddress } from "../contractAddresses";
require("dotenv").config()

async function main() {
    // const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string)
    const [deployer] = await ethers.getSigners();
    // const signer = await ethers.getSigner(wallet)
    const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_SEPOLIA_RPC_URL)
    const cotract:any = new ethers.Contract(
        // goerliAnfiFactoryAddress, //factory goerli
        sepoliaARBEIIndexFactoryAddress, //factory goerli
        Factory_ABI,
        provider
    )

    const addresses = [
        sepoliaTestArbitrumAddress,
        sepoliaTestAAVEAddress,
        sepoliaTestCLIPPERAddress,
        sepoliaTestPENDLEAddress,
        sepoliaTestSILOAddress,
        sepoliaTestCAKEAddress,
        sepoliaTestDODOAddress,
        sepoliaTestSALEAddress,
        sepoliaTestPNPAddress,
        sepoliaTestCVXAddress,
        sepoliaTestJOEAddress
    ];

    const marketShares = [
        "15000000000000000000", // sepoliaTestArbitrumAddress
        "12500000000000000000", // sepoliaTestAAVEAddress
        "12500000000000000000", // sepoliaTestCLIPPERAddress
        "9375000000000000000", // sepoliaTestPENDLEAddress
        "9375000000000000000", // sepoliaTestSILOAddress
        "7500000000000000000", // sepoliaTestCAKEAddress
        "7500000000000000000", // sepoliaTestDODOAddress
        "7500000000000000000", // sepoliaTestSALEAddress
        "6250000000000000000", // sepoliaTestPNPAddress
        "6250000000000000000", // sepoliaTestCVXAddress
        "6250000000000000000", // sepoliaTestJOEAddress
    ]

    const swapVersions = [
        "3",
        "3",
        "3",
        "3",
        "3",
        "3",
        "3",
        "3",
        "3",
        "3",
        "3"
    ]

    // await wallet.connect(provider);
    console.log("sending data...")
    const result = await cotract.connect(deployer).mockFillAssetsList(
        addresses,
        marketShares,
        swapVersions
        // [sepoliaXautAddress, sepoliaBitcoinAddress],
        // ["70000000000000000000", "30000000000000000000"],
        // ["3", "3"]
    )
    console.log("waiting for results...")
    const receipt = await result.wait();
    if(receipt.status ==1 ){
        console.log("success =>", receipt)
    }else{
        console.log("failed =>", receipt)
    }
}

main()