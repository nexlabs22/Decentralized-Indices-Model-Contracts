import { ethers, upgrades } from "hardhat";
import { goerliAnfiIndexTokenAddress, goerliEthUsdPriceFeed, goerliExternalJobIdBytes32, goerliFactoryV2Address, goerliFactoryV3Address, goerliLinkAddress, goerliOracleAdress, goerliQouterAddress, goerliRouterV2Address, goerliRouterV3Address, goerliWethAddress, seploliaWethAddress, sepoliaAnfiIndexTokenAddress, sepoliaEthUsdPriceFeed, sepoliaFactoryV3Address, sepoliaLinkAddress, sepoliaRouterV3Address, sepoliaSCIIndexTokenAddress } from "../contractAddresses";
// const { ethers, upgrades, network, hre } = require('hardhat');

async function deployIndexToken() {
  
  const [deployer] = await ethers.getSigners();

  const IndexToken = await ethers.getContractFactory("IndexFactory");
  console.log('Deploying IndexFactory...');

  const indexToken = await upgrades.deployProxy(IndexToken, [
      sepoliaSCIIndexTokenAddress, //token
      sepoliaLinkAddress, //link token address
      goerliOracleAdress, //oracle address
      goerliExternalJobIdBytes32, // jobId
      sepoliaEthUsdPriceFeed, // price feed
      seploliaWethAddress, //weth address
      goerliQouterAddress, // qoute
      sepoliaRouterV3Address, // routerv3
      sepoliaFactoryV3Address, //factoryv3
      goerliRouterV2Address, //routerv2
      goerliFactoryV2Address //factoryv2
  ], { initializer: 'initialize' });

  await indexToken.waitForDeployment()

  console.log(
    `IndexToken deployed: ${ await indexToken.getAddress()}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployIndexToken().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});