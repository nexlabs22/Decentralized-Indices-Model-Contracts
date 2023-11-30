import { ethers, upgrades } from "hardhat";
import { goerliAnfiIndexTokenAddress, goerliEthUsdPriceFeed, goerliExternalJobIdBytes32, goerliFactoryV2Address, goerliFactoryV3Address, goerliLinkAddress, goerliOracleAdress, goerliQouterAddress, goerliRouterV2Address, goerliRouterV3Address, goerliWethAddress } from "../contractAddresses";
// const { ethers, upgrades, network, hre } = require('hardhat');

async function deployIndexToken() {
  
  const [deployer] = await ethers.getSigners();

  const IndexToken = await ethers.getContractFactory("IndexFactory");
  console.log('Deploying IndexFactory...');

  const indexToken = await upgrades.deployProxy(IndexToken, [
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