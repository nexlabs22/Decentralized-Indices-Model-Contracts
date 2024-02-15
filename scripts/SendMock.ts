import { ethers } from "hardhat";
import {
    abi as Factory_ABI,
    bytecode as Factory_BYTECODE,
  } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import { IndexFactory } from "../typechain-types";
import { goerliAnfiFactoryAddress, sepoliaAnfiFactoryAddress, sepoliaBitcoinAddress, sepoliaXautAddress } from "../contractAddresses";
require("dotenv").config()

async function main() {
    // const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string)
    const [deployer] = await ethers.getSigners();
    // const signer = await ethers.getSigner(wallet)
    const provider = new ethers.JsonRpcProvider(process.env.ETHEREUM_SEPOLIA_RPC_URL)
    const cotract:any = new ethers.Contract(
        // goerliAnfiFactoryAddress, //factory goerli
        sepoliaAnfiFactoryAddress, //factory goerli
        Factory_ABI,
        provider
    )
    // await wallet.connect(provider);
    console.log("sending data...")
    const result = await cotract.connect(deployer).mockFillAssetsList(
        [sepoliaXautAddress, sepoliaBitcoinAddress],
        ["70000000000000000000", "30000000000000000000"],
        ["3", "3"]
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