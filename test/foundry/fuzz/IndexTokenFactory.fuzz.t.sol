// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../../contracts/token/IndexToken.sol";
import "../../../contracts/factory/IndexFactory.sol";
// import "../../../contracts/test/TestSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../../../contracts/test/MockV3Aggregator.sol";
import "../../../contracts/test/MockApiOracle.sol";
import "../../../contracts/test/LinkToken.sol";
import "../../../contracts/interfaces/IUniswapV3Pool.sol";
import "../../../contracts/test/MockV3Aggregator.sol";

import "../ContractDeployer.sol";

contract IndexTokenFactoryFuzzTests is Test, ContractDeployer {

    using stdStorage for StdStorage;

    uint256 internal constant SCALAR = 1e20;

    uint256 internal constant TOKEN_LIQUIDITY_LIMIT = 1000000e18;
    uint256 internal constant WETH_LIQUIDITY_LIMIT = 1000e18;

    
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
        
        deployAllContracts(TOKEN_LIQUIDITY_LIMIT * 1000);
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        addLiquidityETH(positionManager, factoryAddress, usdt, wethAddress, TOKEN_LIQUIDITY_LIMIT, WETH_LIQUIDITY_LIMIT);
        
    }

    function testInitialized() public {
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000e18);
        assertEq(indexToken.minter(), address(factory));
    }

    
    function updateOracleList() public {
        address[] memory assetList = new address[](5);
        assetList[0] = address(token0);
        assetList[1] = address(token1);
        assetList[2] = address(token2);
        assetList[3] = address(token3);
        assetList[4] = address(token4);

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
        bytes32 requestId = factoryStorage.requestAssetsData();
        oracle.fulfillOracleFundingRateRequest(requestId, assetList, tokenShares, swapVersions);
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
        
        // token shares
        assertEq(factoryStorage.tokenSwapFee(address(token0)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token1)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token2)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token3)), 3000);
        assertEq(factoryStorage.tokenSwapFee(address(token4)), 3000);
        
    }


    function testFuzzIssuanceWithTokens(uint256 amount) public {
        vm.assume(amount + 1e18 < TOKEN_LIQUIDITY_LIMIT);    
        updateOracleList();
        
        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, amount + 1e18);
        vm.startPrank(add1);

        usdt.approve(address(factory), amount + 1e18);
        factory.issuanceIndexTokens(address(usdt), amount, 3000);
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
        assertEq(indexToken.balanceOf(add1), 0);

    }

    
    
}