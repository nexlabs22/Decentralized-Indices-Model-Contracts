import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
//   import { ethers } from "hardhat";
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
    abi as QOUTER_ABI,
    bytecode as QOUTER_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json'
  import {
    abi as PDESCRIPTOR_ABI,
    bytecode as PDESCRIPTOR_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json'
  import {
    abi as NFTDESCRIPTOR_ABI,
    bytecode as NFTDESCRIPTOR_BYTECODE,
  } from '@uniswap/v3-periphery/artifacts/contracts/libraries/NFTDescriptor.sol/NFTDescriptor.json'
import { INonfungiblePositionManager, IQuoter, ISwapRouter, IUniswapV3Factory, WETH9 } from "../../typechain-types";
// import WETH9Obj from '../../artifacts/contracts/WETH9.sol/WETH9.json'
import WETH9Obj from '../../artifacts/contracts/uniswap/WETH9.sol/WETH9.json'
import { encodePriceSqrt } from './utils/encodePriceSqrt';
import { encodePath } from "./utils/path";
import { getMaxTick, getMinTick } from "./utils/ticks";
import { FeeAmount, TICK_SPACINGS } from './utils/constants';
import { Block, formatEther, parseEther } from "ethers";
import { ethers, upgrades } from "hardhat";

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
      const btcToken = await Token.deploy(ethers.parseEther("100000"));
      const btcTokenAddress = await btcToken.getAddress()
      const xautToken = await Token.deploy(ethers.parseEther("100000"));
      const xautTokenAddress = await xautToken.getAddress()
      //nft descriptor
      const nftDescriptorLibraryFactory = new ethers.ContractFactory(NFTDESCRIPTOR_ABI, NFTDESCRIPTOR_BYTECODE, owner)
      const nftDescriptorLibrary = await nftDescriptorLibraryFactory.deploy()
      const nftDescriptorLibraryAddress = await nftDescriptorLibrary.getAddress()
      
      //qouter contract
      const contractQouter = new ethers.ContractFactory(QOUTER_ABI, QOUTER_BYTECODE, owner);
      const qouter = await contractQouter.deploy(
        factoryAddress,
        wethAddress
      ) as IQuoter;
      const qouterAddress = await qouter.getAddress();

      
      //position manager
      //nft descriptor
      const positionManagerFactory = new ethers.ContractFactory(PMANAGER_ABI, PMANAGER_BYTECODE, owner)
      const nft = await positionManagerFactory.deploy(
        factoryAddress,
        wethAddress,
        token0Address// nftDescriptorAddress
      ) as INonfungiblePositionManager

      const nftAddress = await nft.getAddress()
      

      //deploy index token
      const IndexToken = await ethers.getContractFactory("IndexToken");
      const indexToken = await await upgrades.deployProxy(IndexToken, [
        "Anti Inflation Index token",
        "ANFI",
        '1000000000000000000', // 1e18
        owner.address,
        '1000000000000000000000000', // 1000000e18
        wethAddress,
        qouterAddress,
        routerAddress,
        factoryAddress,
        routerAddress, //should be v2
        factoryAddress //should be v2
    ], { initializer: 'initialize' });
    const indexTokenAddress = await indexToken.getAddress();

    //deploy link token
    const LinkToken = await ethers.getContractFactory("LinkToken");
    const linkToken = await LinkToken.deploy();
    const linkTokenAddress = await linkToken.getAddress()
    //deploy oracle
    const Oracle = await ethers.getContractFactory("MockApiOracle");
    const oracle = await Oracle.deploy(linkTokenAddress);
    const oracleAddress = await oracle.getAddress()
    //deploy eth price oracle
    const EthPriceOracle = await ethers.getContractFactory("MockV3Aggregator");
    const ethPriceOracle = await EthPriceOracle.deploy("18", ethers.parseEther("2000"));
    const ethPriceOracleAddress = await ethPriceOracle.getAddress()
    //deploy index factory
    const IndexFactory = await ethers.getContractFactory("IndexFactory");
    const indexFactory = await await upgrades.deployProxy(IndexFactory, [
        indexTokenAddress,
        // address(0),
        linkTokenAddress,
        oracleAddress,
        "0x3938616166333430373765633464306661346232643363356461626635653635", //jobId
        ethPriceOracleAddress,
        //swap addresses
        wethAddress,
        qouterAddress,
        routerAddress,
        factoryAddress,
        routerAddress, //should be v2
        factoryAddress //should be v2
  ], { initializer: 'initialize' });

      const indexFactoryAddress = await indexFactory.getAddress()
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
        btcToken,
        btcTokenAddress,
        xautToken,
        xautTokenAddress,
        nft,
        nftAddress,
        linkToken,
        linkTokenAddress,
        oracle,
        oracleAddress,
        ethPriceOracle,
        ethPriceOracleAddress,
        indexToken,
        indexTokenAddress,
        indexFactory,
        indexFactoryAddress
        };
    }
    async function addLiquidity(
        token0Address: string,
        token1Address: string,
        token0Amount: number,
        token1Amount:number,
    ) {
        const fixtureObject = await loadFixture(deployOneYearLockFixture);
        const token0Contract = await ethers.getContractAt("Token", token0Address);
        const token1Contract = await ethers.getContractAt("Token", token1Address);
        await token0Contract.approve(fixtureObject.nftAddress, parseEther(token0Amount.toString()))
        await token1Contract.approve(fixtureObject.nftAddress, parseEther(token1Amount.toString()))
        console.log("Allowance0", ethers.formatEther(await token0Contract.allowance(fixtureObject.owner.address, fixtureObject.nftAddress)));
        console.log("Allowance1", ethers.formatEther(await token1Contract.allowance(fixtureObject.owner.address, fixtureObject.nftAddress)));
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;
        await fixtureObject.nft.createAndInitializePoolIfNecessary(
            token0Address,
            token1Address,
            "3000",
            encodePriceSqrt(1, 1)
          )
        const liquidityParams = {
            token0: token0Address,
            token1: token1Address,
            fee: "3000",
            tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
            tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
            recipient: await fixtureObject.owner.getAddress(),
            amount0Desired: parseEther(token0Amount.toString()),
            amount1Desired: parseEther(token1Amount.toString()),
            amount0Min: 0,
            amount1Min: 0,
            deadline: unlockTime,
            }
            
            await fixtureObject.nft.mint(liquidityParams)
        // cosnt token1Contract = new ethers.Contract(token0Address, )
    }

    async function addLiquidityETH(
        token0Address: string,
        token1Address: string,
        token0Amount: number,
        token1Amount:number,
    ) {
        const fixtureObject = await loadFixture(deployOneYearLockFixture);
        // const token0Contract = await ethers.getContractAt("WET", token0Address);
        const token1Contract = await ethers.getContractAt("Token", token1Address);
        await fixtureObject.weth.deposit({value:ethers.parseEther(token0Amount.toString())});
        await fixtureObject.weth.approve(fixtureObject.nftAddress, parseEther(token0Amount.toString()))
        await token1Contract.approve(fixtureObject.nftAddress, parseEther(token1Amount.toString()))
        // console.log("Allowance0", ethers.formatEther(await fixtureObject.weth.allowance(fixtureObject.owner.address, fixtureObject.nftAddress)));
        // console.log("Allowance1", ethers.formatEther(await token1Contract.allowance(fixtureObject.owner.address, fixtureObject.nftAddress)));
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;
        // console.log("weth address", await fixtureObject.weth.getAddress())
        // console.log("token0Add", token0Address.toLocaleLowerCase())
        // console.log("token1Add", token1Address)
        // return;
        await fixtureObject.nft.createAndInitializePoolIfNecessary(
            token1Address,
            token0Address,
            FeeAmount.MEDIUM,
            encodePriceSqrt(1, 1)
          )
        // return;
        const liquidityParams = {
            token0: token1Address,
            token1: token0Address,
            fee: "3000",
            tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
            tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
            recipient: await fixtureObject.owner.getAddress(),
            amount0Desired: parseEther(token1Amount.toString()),
            amount1Desired: parseEther(token0Amount.toString()),
            amount0Min: 0,
            amount1Min: 0,
            deadline: unlockTime,
            }
            
            await fixtureObject.nft.mint(liquidityParams)
        // cosnt token1Contract = new ethers.Contract(token0Address, )
    }

    async function updateOracleList() {
      const fixtureObject = await loadFixture(deployOneYearLockFixture);
      const assetList = [
        fixtureObject.btcTokenAddress,
        fixtureObject.xautTokenAddress
      ]
      const tokenShares = [
        "30000000000000000000",
        "70000000000000000000"
      ]
      const swapVersions = [
        "3",
        "3"
      ]
      // console.log(link.balanceOf(address(this)));
      // console.log(link.balanceOf(address(this)));
      // link.transfer(address(factory), 1e18);
      await fixtureObject.linkToken.transfer(fixtureObject.indexFactoryAddress, parseEther("1"));
      const transaction = await fixtureObject.indexFactory.requestAssetsData();
      // console.log("transaction:", transaction)
      const transactionReceipt = await transaction.wait()
      // console.log("receipt:", transactionReceipt.logs[0].topics[1])
      // return;
      const requestId: string = transactionReceipt.logs[0].topics[1]
      await fixtureObject.oracle.fulfillOracleFundingRateRequest(requestId, assetList, tokenShares, swapVersions);
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
        // console.log("owner: ", await factory.owner());
        // console.log("owner: ", await router.getAddress());
        
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
        // console.log("token0 before swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        // console.log("token1 before swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))
        await token0.approve(routerAddress, parseEther("10"));
        await router.exactInputSingle(params1);
        // console.log("token0 after swap:", ethers.formatEther(await token0.balanceOf(ownerAddress)))
        // console.log("token1 after swap:", ethers.formatEther(await token1.balanceOf(ownerAddress)))
        
        // await addLiquidity(token0Address, token1Address, 1000, 1000)
        await addLiquidityETH(wethAddress, token1Address, 1, 1000)
      });
  
     
    });



    describe("FactoryTest", function () {
      it("Should set the right unlockTime", async function () {
        const FixtureObject = await loadFixture(deployOneYearLockFixture);
        await addLiquidityETH(FixtureObject.wethAddress, FixtureObject.btcTokenAddress, 1, 1000)
        await addLiquidityETH(FixtureObject.wethAddress, FixtureObject.xautTokenAddress, 1, 1000)
        await updateOracleList()
        const inputAmount = 0.001
        const finalInputAmount = 0.001*10/10000
        console.log(Number(inputAmount.toString()))
        console.log(Number(finalInputAmount.toString()))
        console.log(Number(await FixtureObject.indexFactory.feeRate()))
        await FixtureObject.indexFactory.issuanceIndexTokensWithEth("10000000000000000", {vaule: ("20100000000000000")})

        
        
      });
  
     
    });
  
    
  });
  