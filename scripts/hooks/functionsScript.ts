// This functions get details about Star Wars characters. This example will showcase usage of HTTP requests and console.logs.
// 1, 2, 3 etc.
// Imports
// const ethers = await import("npm:ethers@6.10.0");
// const ethers = await import("npm:ethers@6.0.0");
import { ethers } from "hardhat";

async function main() {

// const characterId = args[0]

// Execute the API request (Promise)
// const apiResponse = await Functions.makeHttpRequest({
//   url: `https://vercel-cron-xi.vercel.app/api/getArbInData`
// })
const apiResponse = await fetch("https://vercel-cron-xi.vercel.app/api/getArbInData")


const data = apiResponse;
console.log(data);
// console.log('API response data:', JSON.stringify(data))
// console.log('API response data:', data.data.arbitrumOne_tokenAddresses)
// console.log('API response data:', data.data.weights)
// console.log('API response data:', data.data.swapVersions)
// const uintArray = [50, 66, 82, 77, 98]
// Return Character Name
// return Functions.encodeString("HHH")
// ABI encoding
// const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(
//   ["address[]", "uint256[]", "uint24[]"],
//   [data.data.arbitrumOne_tokenAddresses, data.data.weights, data.data.swapVersions]
// );

// const dataSize = ethers.utils.arrayify(encodedData).length;

// console.log("Encoded Data Size (bytes):", encodedData);

// Decode the Data
// const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
//     [
//         "address[]", // First array (address[])
//         "uint256[]",
//         "uint24[]"
//     ],
//     encodedData
// );

// console.log("Decoded Address Array:", decoded[0]); // Decoded address array
// console.log("Decoded Address Array:", decoded[1]); // Decoded address array
// console.log("Decoded Address Array:", decoded[2]); // Decoded address array
// console.log("Decoded Uint Array:", decoded[0]);    // Decoded uint array

// return ethers.getBytes(encodedData);

// return Functions.encodeString("HHH");

}

main()
