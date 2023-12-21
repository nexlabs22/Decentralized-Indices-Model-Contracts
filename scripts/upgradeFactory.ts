// import { goerliAnfiIndexToken, goerliUsdtAddress, goerliAnfiFactory, goerliAnfiNFT } from "../network";
import { goerliAnfiFactoryAddress, goerliAnfiIndexTokenAddress, goerliEthUsdPriceFeed, goerliExternalJobIdBytes32, goerliFactoryV2Address, goerliFactoryV3Address, goerliLinkAddress, goerliOracleAdress, goerliQouterAddress, goerliRouterV2Address, goerliRouterV3Address, goerliWethAddress } from "../contractAddresses";

// import { ethers, upgrades } from "hardhat";
const { ethers, upgrades, network, hre } = require('hardhat');

async function deployFactory() {
  
  const [deployer] = await ethers.getSigners();

  const IndexFactory = await ethers.getContractFactory("IndexFactory");
  console.log('Deploying IndexFactory...');
  
  const indexFactory = await upgrades.upgradeProxy(goerliAnfiFactoryAddress, IndexFactory, [
    goerliAnfiIndexTokenAddress, //token
    goerliLinkAddress, //link token address
    goerliOracleAdress, //oracle address
    goerliExternalJobIdBytes32, // jobId
    goerliEthUsdPriceFeed, // price feed
    goerliWethAddress, //weth address
    goerliQouterAddress, // qoute
    goerliRouterV3Address, // routerv3
    goerliFactoryV3Address, //factoryv3
    goerliRouterV2Address, //routerv2
    goerliFactoryV2Address //factoryv2
  ], { initializer: 'initialize' });

  console.log('box upgraed.')
//   await indexFactory.waitForDeployment()

//   console.log(
//     `IndexFactory proxy upgraded by:${ await indexFactory.getAddress()}`
//   );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployFactory().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});