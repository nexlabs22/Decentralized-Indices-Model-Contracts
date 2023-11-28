import { ethers } from "hardhat";
import {
    abi as Factory_ABI,
    bytecode as Factory_BYTECODE,
  } from '../artifacts/contracts/factory/IndexFactory.sol/IndexFactory.json'
import { IndexFactory } from "../typechain-types";
require("dotenv").config()

async function main() {
    // const signer = new ethers.Wallet(process.env.PRIVATE_KEY as string)
    const [deployer] = await ethers.getSigners();
    // const signer = await ethers.getSigner(wallet)
    const provider = new ethers.JsonRpcProvider(process.env.GOERLI_RPC_URL)
    const cotract:any = new ethers.Contract(
        "0x98C6E4a07aD42acC3Fb92F34FB3Bac23E296Ccc2", //factory goerli
        Factory_ABI,
        provider
    )
    // await wallet.connect(provider);
    console.log("sending data...")
    const result = await cotract.connect(deployer).mockFillAssetsList(
        ["0x99AB2160dDAe7003b46e09118aC5C379A4823E98","0xfeC3D2CEA6f85Cdf236c7205Fb8EdD4eBF29789D"],
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