import { ethers } from "hardhat";
// import {
//     abi as Factory_ABI,
//     bytecode as Factory_BYTECODE,
//   } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import {
    abi as Factory_ABI,
    bytecode as Factory_BYTECODE,
  } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import { sepoliaAnfiFactoryAddress, sepoliaSCIFactoryAddress } from "../contractAddresses";
// import { IndexFactory } from "../../typechain-types";
// import { mumbaiChainSelector, mumbaiTestRippleAddress, sepoliaBitcoinAddress, sepoliaCR5IndexFactory, sepoliaCR5IndexFactoryStorage, sepoliaChainSelector, sepoliaTestBinanceAddress, sepoliaTestEthereumAddress, sepoliaTestSolanaAddress, testSepoliaCR5IndexFactory } from "../../network";
// import { goerliAnfiFactoryAddress } from "../contractAddresses";
require("dotenv").config()

async function main() {
    // const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string)
    const [deployer] = await ethers.getSigners();
    // const signer = await ethers.getSigner(wallet)
    // const provider = new ethers.JsonRpcProvider(process.env.GOERLI_RPC_URL)
    const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_SEPOLIA_RPC_URL)
    const cotract:any = new ethers.Contract(
        sepoliaSCIFactoryAddress as string, //factory goerli
        // testSepoliaCR5IndexFactory as string, //factory goerli
        Factory_ABI,
        provider
    )
    // await wallet.connect(provider);
    console.log("sending data...")
    const result = await cotract.connect(deployer).issuanceIndexTokensWithEth(
        ethers.parseEther("0.001"),
        {value: ethers.parseEther("0.0011"), gasLimit: 2000000}
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