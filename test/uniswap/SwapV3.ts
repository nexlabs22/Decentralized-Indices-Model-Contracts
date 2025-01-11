import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  import {
    abi as FACTORY_ABI,
    bytecode as FACTORY_BYTECODE,
  } from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'
  import {
    abi as ROUTER_ABI,
    bytecode as ROUTER_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json'
  import {
    abi as PMANAGER_ABI,
    bytecode as PMANAGER_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json'
  import {
    abi as PDESCRIPTOR_ABI,
    bytecode as PDESCRIPTOR_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json'
  import {
    abi as NFTDESCRIPTOR_ABI,
    bytecode as NFTDESCRIPTOR_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/libraries/NFTDescriptor.sol/NFTDescriptor.json'
import { INonfungiblePositionManager, ISwapRouter, IUniswapV3Factory, WETH9 } from "../../typechain-types";
// import WETH9Obj from '../../artifacts/contracts/WETH9.sol/WETH9.json'
import WETH9Obj from '../../artifacts/contracts/uniswap/WETH9.sol/WETH9.json'
import { encodePriceSqrt } from './utils/encodePriceSqrt';
import { encodePath } from "./utils/path";
import { getMaxTick, getMinTick } from "./utils/ticks";
import { FeeAmount, TICK_SPACINGS } from "./utils/constants";
import { Block, formatEther, parseEther } from "ethers";

  describe("Lock", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployOneYearLockFixture() {
      
  
      // Contracts are deployed using the first signer/account by default
      const [owner, otherAccount] = await ethers.getSigners();
  
      
      //factory contract
      const contractFactory = new ethers.ContractFactory(FACTORY_ABI, FACTORY_BYTECODE, owner);
      const factory = await contractFactory.deploy() as IUniswapV3Factory;
      const factoryAddress = await factory.getAddress();
      //weth contract
      const contractWeth = new ethers.ContractFactory(WETH9Obj.abi, WETH9Obj.bytecode, owner);
      const weth = await contractWeth.deploy() as (WETH9);
      const wethAddress = await weth.getAddress();
      //router contract
      const contractRouter = new ethers.ContractFactory(ROUTER_ABI, ROUTER_BYTECODE, owner);
      const router = await contractRouter.deploy(
        factoryAddress,
        wethAddress
      ) as ISwapRouter;
      const routerAddress = await router.getAddress();
      //token
      const Token = await ethers.getContractFactory("Token");
      const token0 = await Token.deploy(ethers.parseEther("100000"));
      const token0Address = await token0.getAddress()
      const token1 = await Token.deploy(ethers.parseEther("100000"));
      const token1Address = await token1.getAddress()
      //nft descriptor
      const nftDescriptorLibraryFactory = new ethers.ContractFactory(NFTDESCRIPTOR_ABI, NFTDESCRIPTOR_BYTECODE, owner)
      const nftDescriptorLibrary = await nftDescriptorLibraryFactory.deploy()
      const nftDescriptorLibraryAddress = await nftDescriptorLibrary.getAddress()
      
      //position descriptor
    //   const positionDescriptorFactory = new ethers.ContractFactory(PDESCRIPTOR_ABI, PDESCRIPTOR_BYTECODE, owner)
    //   const nftDescriptor = await positionDescriptorFactory.deploy(
    //     token0Address,
    //     // 'ETH' as a bytes32 string
    //     '0x4554480000000000000000000000000000000000000000000000000000000000'
    //   )
    //   const nftDescriptorAddress = await nftDescriptor.getAddress()
      
      //position manager
      //nft descriptor
      const positionManagerFactory = new ethers.ContractFactory(PMANAGER_ABI, PMANAGER_BYTECODE, owner)
      const nft = await positionManagerFactory.deploy(
        factoryAddress,
        wethAddress,
        token0Address// nftDescriptorAddress
      ) as INonfungiblePositionManager

      const nftAddress = await nft.getAddress()
        
      return { 
        factory, 
        factoryAddress, 
        router, 
        routerAddress, 
        weth, 
        wethAddress, 
        owner, 
        otherAccount, 
        token0,
        token0Address, 
        token1,
        token1Address,
        nft,
        nftAddress
        };
    }
  
    describe("Deployment", function () {
      it("Should set the right unlockTime", async function () {
        const { 
            factory, 
            factoryAddress, 
            router, 
            routerAddress, 
            weth, 
            wethAddress, 
            owner, 
            otherAccount,
            token0, 
            token0Address, 
            token1,
            token1Address,
            nft,
            nftAddress
         } = await loadFixture(deployOneYearLockFixture);
        console.log("owner: ", await factory.owner());
        console.log("owner: ", await router.getAddress());
        
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

        await nft.createAndInitializePoolIfNecessary(
            token0Address,
            token1Address,
            "3000",
            encodePriceSqrt(1, 1)
          )
        await token0.approve(nftAddress, parseEther("1000"));
        await token1.approve(nftAddress, parseEther("1000"));
        // const block = new Block()
        const liquidityParams = {
        token0: token0Address,
        token1: token1Address,
        fee: "3000",
        tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
        tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
        recipient: await owner.getAddress(),
        amount0Desired: parseEther("1000"),
        amount1Desired: parseEther("1000"),
        amount0Min: 0,
        amount1Min: 0,
        deadline: unlockTime,
        }
        
        await nft.mint(liquidityParams)

         const tokens = [token0Address, token1Address]
        //   const params = {
        //     path: encodePath(tokens, new Array(tokens.length - 1).fill(3000)),
        //     recipient: await owner.getAddress(),
        //     deadline: unlockTime,
        //     // amountIn: ethers.parseEther("1"),
        //     amountIn: parseEther("10"),
        //     amountOutMinimum: 0,
        //   }
        // const ownerAddress = owner.getAddress()
        // console.log("token0 before swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        // console.log("token1 before swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))
        // await token0.approve(routerAddress, parseEther("10"));
        // await router.exactInput(params);
        // console.log("token0 after swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        // console.log("token1 after swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))

        const params1 = {
            tokenIn: tokens[0],
            tokenOut: tokens[1],
            fee: FeeAmount.MEDIUM,
            recipient: await owner.getAddress(),
            deadline: unlockTime,
            // amountIn: ethers.parseEther("1"),
            amountIn: parseEther("10"),
            amountOutMinimum:0,
            sqrtPriceLimitX96: 0
        }
        const ownerAddress = owner.getAddress()
        console.log("token0 before swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        console.log("token1 before swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))
        await token0.approve(routerAddress, parseEther("10"));
        await router.exactInputSingle(params1);
        console.log("token0 after swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        console.log("token1 after swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))
        
      });
  
     
    });
  
    
  });
  