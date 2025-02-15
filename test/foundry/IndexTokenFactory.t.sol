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

contract IndexTokenFactoryTest is Test, ContractDeployer {

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

    receive() external payable {}

    function setUp() public {
        
        deployAllContracts(1000000e18);
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 100000e18, 100e18);
        addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, 100000e18, 100e18);
        addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, 100000e18, 100e18);
        addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, 100000e18, 100e18);
        addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, 100000e18, 100e18);
        addLiquidityETH(positionManager, factoryAddress, usdt, wethAddress, 100000e18, 100e18);
        
    }

    function testInitialized() public {
        // counter.increment();
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000000e18);
        assertEq(indexToken.minter(), address(factory));
    }

    
    function updateOracleList() public {
        address[] memory assetList = new address[](5);
        assetList[0] = address(token0);
        assetList[1] = address(token1);
        assetList[2] = address(token2);
        assetList[3] = address(token3);
        assetList[4] = address(token4);

        uint24[] memory feesData = new uint24[](1);
        feesData[0] = 3000;

        bytes[] memory pathData = new bytes[](5);
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

        uint[] memory tokenShares = new uint[](5);
        tokenShares[0] = 20e18;
        tokenShares[1] = 20e18;
        tokenShares[2] = 20e18;
        tokenShares[3] = 20e18;
        tokenShares[4] = 20e18;

        uint[] memory swapVersions = new uint[](5);
        swapVersions[0] = 3000;
        swapVersions[1] = 3000;
        swapVersions[2] = 3000;
        swapVersions[3] = 3000;
        swapVersions[4] = 3000;
        
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
        bytes memory data = abi.encode(assetList, pathData, tokenShares, swapVersions);
        bool success = oracle.fulfillRequest(address(factoryStorage), requestId, data);
        require(success, "oracle request failed");
    }


    function updateOracleList2() public {
        address[] memory assetList = new address[](5);
        assetList[0] = address(token0);
        assetList[1] = address(token1);
        assetList[2] = address(token2);
        assetList[3] = address(token3);
        assetList[4] = address(token4);

        uint[] memory tokenShares = new uint[](5);
        tokenShares[0] = 30e18;
        tokenShares[1] = 20e18;
        tokenShares[2] = 20e18;
        tokenShares[3] = 20e18;
        tokenShares[4] = 10e18;

        
        
        uint24[] memory feesData = new uint24[](1);
        feesData[0] = 3000;

        bytes[] memory pathData = new bytes[](5);
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


        // link.transfer(address(factoryStorage), 1e17);
        bytes32 requestId = factoryStorage.requestAssetsData(
            "console.log('Hello, World!');",
            // FunctionsConsumer.Location.Inline, // Use the imported enum directly
            abi.encodePacked("default"),
            new string[](1), // Convert to dynamic array
            new bytes[](1),  // Convert to dynamic array
            0,
            0
        );
        bytes memory data = abi.encode(assetList, pathData, tokenShares);
        bool success = oracle.fulfillRequest(address(factoryStorage), requestId, data);
        require(success, "oracle request failed 2");
    }

    function testOracleList() public {
        updateOracleList();
        // token  oracle list
        assertEq(factoryStorage.oracleList(0), address(token0));
        assertEq(factoryStorage.oracleList(1), address(token1));
        assertEq(factoryStorage.oracleList(2), address(token2));
        assertEq(factoryStorage.oracleList(3), address(token3));
        assertEq(factoryStorage.oracleList(4), address(token4));
        // token current list
        assertEq(factoryStorage.currentList(0), address(token0));
        assertEq(factoryStorage.currentList(1), address(token1));
        assertEq(factoryStorage.currentList(2), address(token2));
        assertEq(factoryStorage.currentList(3), address(token3));
        assertEq(factoryStorage.currentList(4), address(token4));
        // token shares
        assertEq(factoryStorage.tokenOracleMarketShare(address(token0)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token1)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token2)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token3)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token4)), 20e18);
        
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
        
        factory.issuanceIndexTokensWithEth{value: (1e18*1001)/1000}(1e18);
        factory.issuanceIndexTokensWithEth{value: (1e18*1001)/1000}(1e18);
        // redemption input token path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), path, fees);
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
        
        factory.issuanceIndexTokens(address(usdt), path0, fees0, 1000e18);
        console.log("index token balance after isssuance", indexToken.balanceOf(address(add1)));
        console.log("index token price after isssuance", factoryStorage.getIndexTokenPrice());
        console.log("portfolio value after issuance", factoryStorage.getPortfolioBalance());
        // redemption input token path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        uint reallOut = factory.redemption(indexToken.balanceOf(address(add1)), address(weth), path, fees);
        console.log("index token balance after redemption", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after redemption", factoryStorage.getPortfolioBalance());
        console.log("real out", reallOut);
    }

    
    function testIssuanceWithTokensOutput() public {
        
       
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

        factory.issuanceIndexTokens(address(usdt), path0, fees0, 1000e18);
        console.log("index token balance after isssuance", indexToken.balanceOf(address(add1)));
        console.log("index token price after isssuance", factoryStorage.getIndexTokenPrice());
        console.log("portfolio value after issuance", factoryStorage.getPortfolioBalance());
        // redemption input token path data
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        uint reallOut = factory.redemption(indexToken.balanceOf(address(add1)), address(usdt), path, fees);
        console.log("index token balance after redemption", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after redemption", factoryStorage.getPortfolioBalance());
        console.log("real out", reallOut);
        console.log("usdt after redemption", usdt.balanceOf(add1));
    }

    
    function testReweighting() public {
        uint startAmount = 1e14;
        
        updateOracleList();
        
        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);
        
        usdt.approve(address(factory), 1001e18);
        // issuance input token path data
        address[] memory path0 = new address[](2);
        path0[0] = address(usdt);
        path0[1] = address(weth);
        uint24[] memory fees0 = new uint24[](1);
        fees0[0] = 3000;
        factory.issuanceIndexTokens(address(usdt), path0, fees0, 1000e18);
        vm.stopPrank();
        //updateOracle
        updateOracleList2();

        assertEq(factoryStorage.tokenOracleMarketShare(address(token0)), 30e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token1)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token2)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token3)), 20e18);
        assertEq(factoryStorage.tokenOracleMarketShare(address(token4)), 10e18);
        
        factoryBalancer.reIndexAndReweight();
    }
    
    

    
}