import { ethers, upgrades } from "hardhat";
import { goerliFactoryV2Address, goerliFactoryV3Address, goerliQouterAddress, goerliRouterV2Address, goerliRouterV3Address, goerliWethAddress, seploliaWethAddress, sepoliaFactoryV3Address, sepoliaRouterV3Address } from "../contractAddresses";
// const { ethers, upgrades, network, hre } = require('hardhat');

async function deployIndexToken() {
  
  const [deployer] = await ethers.getSigners();

  const IndexToken = await ethers.getContractFactory("IndexToken");
  console.log('Deploying IndexToken...');

  const indexToken = await upgrades.deployProxy(IndexToken, [
      "Magnificent 7 Index",
      "MAG7",
      '1000000000000000000', // 1e18
      deployer.address,
      '1000000000000000000000000', // 1000000e18
      seploliaWethAddress,
      goerliQouterAddress,
      sepoliaRouterV3Address,
      sepoliaFactoryV3Address,
      goerliRouterV2Address,
      goerliFactoryV2Address
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