// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/token/IndexToken.sol";
import "../../contracts/factory/IndexFactory.sol";
// import "../../contracts/test/TestSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../../contracts/test/MockV3Aggregator.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";
import "../../contracts/interfaces/IUniswapV3Pool.sol";
import "../../contracts/test/MockV3Aggregator.sol";

import "./ContractDeployer.sol";

contract CounterTest is Test, ContractDeployer {

    using stdStorage for StdStorage;

    uint256 internal constant SCALAR = 1e20;


    uint256 mainnetFork;

    

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    

    event FeeReceiverSet(address indexed feeReceiver);
    event FeeRateSet(uint256 indexed feeRatePerDayScaled);
    event MethodologistSet(address indexed methodologist);
    event MethodologySet(string methodology);
    event MinterSet(address indexed minter);
    event SupplyCeilingSet(uint256 supplyCeiling);
    event MintFeeToReceiver(address feeReceiver, uint256 timestamp, uint256 totalSupply, uint256 amount);
    event ToggledRestricted(address indexed account, bool isRestricted);


    function setUp() public {
        
        deployAllContracts(1000000e18);
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token5, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token6, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token7, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token8, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token9, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, usdt, wethAddress, 1000e18, 1e18);
        
    }

    function testInitialized() public {
        // counter.increment();
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000e18);
        assertEq(indexToken.minter(), address(factory));
    }

    enum DexStatus {
        UNISWAP_V2,
        UNISWAP_V3
    }
    function returnPathData() public returns(bytes[] memory){
        uint24[] memory feesData = new uint24[](1);
        feesData[0] = 3000;

        bytes[] memory pathData = new bytes[](10);
        //updating path data for token0
        address[] memory path0 = new address[](2);
        path0[0] = address(weth);
        path0[1] = address(token0);
        pathData[0] = abi.encode(path0, feesData);
        //updating path data for token1
        address[] memory path1 = new address[](2);
        path1[0] = address(weth);
        path1[1] = address(token1);
        pathData[1] = abi.encode(path1, feesData);
        //updating path data for token2
        address[] memory path2 = new address[](2);
        path2[0] = address(weth);
        path2[1] = address(token2);
        pathData[2] = abi.encode(path2, feesData);
        //updating path data for token3
        address[] memory path3 = new address[](2);
        path3[0] = address(weth);
        path3[1] = address(token3);
        pathData[3] = abi.encode(path3, feesData);
        //updating path data for token4
        address[] memory path4 = new address[](2);
        path4[0] = address(weth);
        path4[1] = address(token4);
        pathData[4] = abi.encode(path4, feesData);
        //updating path data for token5
        address[] memory path5 = new address[](2);
        path5[0] = address(weth);
        path5[1] = address(token5);
        pathData[5] = abi.encode(path5, feesData);
        //updating path data for token6
        address[] memory path6 = new address[](2);
        path6[0] = address(weth);
        path6[1] = address(token6);
        pathData[6] = abi.encode(path6, feesData);
        //updating path data for token7
        address[] memory path7 = new address[](2);
        path7[0] = address(weth);
        path7[1] = address(token7);
        pathData[7] = abi.encode(path7, feesData);
        //updating path data for token8
        address[] memory path8 = new address[](2);
        path8[0] = address(weth);
        path8[1] = address(token8);
        pathData[8] = abi.encode(path8, feesData);
        //updating path data for token9
        address[] memory path9 = new address[](2);
        path9[0] = address(weth);
        path9[1] = address(token9);
        pathData[9] = abi.encode(path9, feesData);

        return pathData;
    }
    function updateOracleList() public {
        address[] memory assetList = new address[](10);
        assetList[0] = address(token0);
        assetList[1] = address(token1);
        assetList[2] = address(token2);
        assetList[3] = address(token3);
        assetList[4] = address(token4);
        assetList[5] = address(token5);
        assetList[6] = address(token6);
        assetList[7] = address(token7);
        assetList[8] = address(token8);
        assetList[9] = address(token9);

        uint[] memory tokenShares = new uint[](10);
        tokenShares[0] = 10e18;
        tokenShares[1] = 10e18;
        tokenShares[2] = 10e18;
        tokenShares[3] = 10e18;
        tokenShares[4] = 10e18;
        tokenShares[5] = 10e18;
        tokenShares[6] = 10e18;
        tokenShares[7] = 10e18;
        tokenShares[8] = 10e18;
        tokenShares[9] = 10e18;

        uint[] memory swapVersions = new uint[](10);
        swapVersions[0] = 3000;
        swapVersions[1] = 3000;
        swapVersions[2] = 3000;
        swapVersions[3] = 3000;
        swapVersions[4] = 3000;
        swapVersions[5] = 3000;
        swapVersions[6] = 3000;
        swapVersions[7] = 3000;
        swapVersions[8] = 3000;
        swapVersions[9] = 3000;
        
        
        bytes[] memory pathData = returnPathData();

        link.transfer(address(factoryStorage), 1e17);
        bytes32 requestId = factoryStorage.requestAssetsData(
            "console.log('Hello, World!');",
            // FunctionsConsumer.Location.Inline, // Use the imported enum directly
            abi.encodePacked("default"),
            new string[](1), // Convert to dynamic array
            new bytes[](1),  // Convert to dynamic array
            0,
            0
        );
        // oracle.fulfillOracleFundingRateRequest(requestId, assetList, tokenShares, swapVersions);
        bytes memory data = abi.encode(assetList, pathData, tokenShares, swapVersions);
        oracle.fulfillRequest(address(factoryStorage), requestId, data);
    }
    function testOracleList() public {
        updateOracleList();
        // token  oracle list
        assertEq(factoryStorage.oracleList(0), address(token0));
        assertEq(factoryStorage.oracleList(1), address(token1));
        assertEq(factoryStorage.oracleList(2), address(token2));
        assertEq(factoryStorage.oracleList(3), address(token3));
        assertEq(factoryStorage.oracleList(4), address(token4));
        assertEq(factoryStorage.oracleList(9), address(token9));
        // token current list
        assertEq(factoryStorage.currentList(0), address(token0));
        assertEq(factoryStorage.currentList(1), address(token1));
        assertEq(factoryStorage.currentList(2), address(token2));
        assertEq(factoryStorage.currentList(3), address(token3));
        assertEq(factoryStorage.currentList(4), address(token4));
        assertEq(factoryStorage.currentList(9), address(token9));
        // token shares
        assertEq(factoryStorage.tokenOracleMarketShare(address(token0)), 10e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token1)), 10e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token2)), 10e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token3)), 10e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token4)), 10e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token9)), 10e18);
        
        // token shares
        assertEq(factoryStorage.tokenSwapFee(address(token0)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token1)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token2)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token3)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token4)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token9)), 3000);

        // token from eth path data
        (address[] memory path0, uint24[] memory fees0) = factoryStorage.getFromETHPathData(address(token0));
        assertEq(path0[0], address(weth));
        assertEq(path0[1], address(token0));
        assertEq(fees0[0], 3000);
        (address[] memory path1, uint24[] memory fees1) = factoryStorage.getFromETHPathData(address(token1));
        assertEq(path1[0], address(weth));
        assertEq(path1[1], address(token1));
        assertEq(fees1[0], 3000);
        (address[] memory path2, uint24[] memory fees2) = factoryStorage.getFromETHPathData(address(token2));
        assertEq(path2[0], address(weth));
        assertEq(path2[1], address(token2));
        assertEq(fees2[0], 3000);
        (address[] memory path3, uint24[] memory fees3) = factoryStorage.getFromETHPathData(address(token3));
        assertEq(path3[0], address(weth));
        assertEq(path3[1], address(token3));
        assertEq(fees3[0], 3000);
        (address[] memory path4, uint24[] memory fees4) = factoryStorage.getFromETHPathData(address(token4));
        assertEq(path4[0], address(weth));
        assertEq(path4[1], address(token4));
        assertEq(fees4[0], 3000);
        (address[] memory path90, uint24[] memory fees90) = factoryStorage.getFromETHPathData(address(token9));
        assertEq(path90[0], address(weth));
        assertEq(path90[1], address(token9));
        assertEq(fees90[0], 3000);

        // token to eth path data
        (address[] memory path5, uint24[] memory fees5) = factoryStorage.getToETHPathData(address(token0));
        assertEq(path5[0], address(token0));
        assertEq(path5[1], address(weth));
        assertEq(fees5[0], 3000);
        (address[] memory path6, uint24[] memory fees6) = factoryStorage.getToETHPathData(address(token1));
        assertEq(path6[0], address(token1));
        assertEq(path6[1], address(weth));
        assertEq(fees6[0], 3000);
        (address[] memory path7, uint24[] memory fees7) = factoryStorage.getToETHPathData(address(token2));
        assertEq(path7[0], address(token2));
        assertEq(path7[1], address(weth));
        assertEq(fees7[0], 3000);
        (address[] memory path8, uint24[] memory fees8) = factoryStorage.getToETHPathData(address(token3));
        assertEq(path8[0], address(token3));
        assertEq(path8[1], address(weth));
        assertEq(fees8[0], 3000);
        (address[] memory path9, uint24[] memory fees9) = factoryStorage.getToETHPathData(address(token4));
        assertEq(path9[0], address(token4));
        assertEq(path9[1], address(weth));
        assertEq(fees9[0], 3000);
        (address[] memory path10, uint24[] memory fees10) = factoryStorage.getToETHPathData(address(token9));
        assertEq(path10[0], address(token9));
        assertEq(path10[1], address(weth));
        assertEq(fees10[0], 3000);

        
    }

    
    function testIssuanceWithEth() public {
        uint startAmount = 1e14;
        

        updateOracleList();
        
        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        payable(add1).transfer(11e18);
        vm.startPrank(add1);
        // console.log("FLOKI", IERC20(FLOKI).balanceOf(address(factory)));
        
        factory.issuanceIndexTokensWithEth{value: (1e18*1001)/1000}(1e18);
        // redemption path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), path, fees, 3000);
    }


    function testIssuanceWithTokens() public {
        uint startAmount = 1e14;
        
        updateOracleList();
        
        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);
        
        usdt.approve(address(factory), 1001e18);

        //issuance input token path data
        address[] memory path0 = new address[](2);
        path0[0] = address(usdt);
        path0[1] = address(weth);
        uint24[] memory fees0 = new uint24[](1);
        fees0[0] = 3000;

        factory.issuanceIndexTokens(address(usdt), path0, fees0, 1000e18, 3000);

        // redemption path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), path, fees, 3000);
    }


    function testIssuanceWithTokensOutput() public {
        uint startAmount = 1e14;
        
       
        updateOracleList();
        
        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);
        usdt.approve(address(factory), 1001e18);

        //issuance input token path data
        address[] memory path0 = new address[](2);
        path0[0] = address(usdt);
        path0[1] = address(weth);
        uint24[] memory fees0 = new uint24[](1);
        fees0[0] = 3000;

        factory.issuanceIndexTokens(address(usdt), path0, fees0, 1000e18, 3000);
        console.log("index token balance after isssuance", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after issuance", factoryStorage.getPortfolioBalance());
        // redemption path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;
        uint reallOut = factory.redemption(indexToken.balanceOf(address(add1)), address(usdt), path, fees, 3000);
        console.log("index token balance after redemption", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after redemption", factoryStorage.getPortfolioBalance());
        console.log("real out", reallOut);
        console.log("usdt after redemption", usdt.balanceOf(add1));
    }
    

    

    

    

    
}