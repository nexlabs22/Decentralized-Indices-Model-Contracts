import { ethers } from "hardhat";
import {
    abi as Factory_ABI,
    bytecode as Factory_BYTECODE,
  } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import { IndexFactory } from "../typechain-types";
import { goerliAnfiFactoryAddress, sepoliaAnfiFactoryAddress, sepoliaBitcoinAddress, sepoliaXautAddress, sepoliaTestArbitrumAddress, sepoliaTestChainLinkAddress, sepoliaTestUniswapAddress, sepoliaTestMakerAddress, sepoliaTestGraphAddress, sepoliaTestGnosisAddress, sepoliaTestLidoAddress, sepoliaTestWOOAddress, sepoliaTestCurveAddress, sepoliaTestCOMPAddress, sepoliaTestFroxSharesAddress, sepoliaSCIFactoryAddress } from "../contractAddresses";
// import { sepoliaTestArbitrumAddress, sepoliaTestChainLinkAddress, sepoliaTestUniswapAddress, sepoliaTestMakerAddress, sepoliaTestGraphAddress, sepoliaTestGnosisAddress, sepoliaTestLidoAddress, sepoliaTestWOOAddress, sepoliaTestCurveAddress, sepoliaTestCOMPAddress, sepoliaTestFroxSharesAddress } from "../contractAddresses";
require("dotenv").config()

async function main() {
    // const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string)
    const [deployer] = await ethers.getSigners();
    // const signer = await ethers.getSigner(wallet)
    const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_SEPOLIA_RPC_URL)
    const cotract:any = new ethers.Contract(
        // goerliAnfiFactoryAddress, //factory goerli
        sepoliaSCIFactoryAddress, //factory goerli
        Factory_ABI,
        provider
    )

    const addresses = [
        sepoliaTestArbitrumAddress,
        sepoliaTestChainLinkAddress,
        sepoliaTestUniswapAddress,
        sepoliaTestMakerAddress,
        sepoliaTestGraphAddress,
        sepoliaTestGnosisAddress,
        sepoliaTestLidoAddress,
        sepoliaTestWOOAddress,
        sepoliaTestCurveAddress,
        sepoliaTestCOMPAddress,
        sepoliaTestFroxSharesAddress
    ];

    const marketShares = [
        "50000000000000000000", // sepoliaTestArbitrumAddress
        "5000000000000000000", // sepoliaTestChainLinkAddress
        "5000000000000000000", // sepoliaTestUniswapAddress
        "5000000000000000000", // sepoliaTestMakerAddress
        "5000000000000000000", // sepoliaTestGraphAddress
        "5000000000000000000", // sepoliaTestGnosisAddress
        "5000000000000000000", // sepoliaTestLidoAddress
        "5000000000000000000", // sepoliaTestWOOAddress
        "5000000000000000000", // sepoliaTestCurveAddress
        "5000000000000000000", // sepoliaTestCOMPAddress
        "5000000000000000000", // sepoliaTestFroxSharesAddress
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