// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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

    receive() external payable {}

    function setUp() public {
        deployAllContracts();
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, 1000e18, 1e18);
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

    function updateOracleList() public {
        address[] memory assetList = new address[](5);
        assetList[0] = address(token0);
        assetList[1] = address(token1);
        assetList[2] = address(token2);
        assetList[3] = address(token3);
        assetList[4] = address(token4);

        uint256[] memory tokenShares = new uint256[](5);
        tokenShares[0] = 20e18;
        tokenShares[1] = 20e18;
        tokenShares[2] = 20e18;
        tokenShares[3] = 20e18;
        tokenShares[4] = 20e18;

        uint256[] memory swapVersions = new uint256[](5);
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

    function testIssuanceWithEth() public {
        uint256 startAmount = 1e14;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        payable(add1).transfer(11e18);
        vm.startPrank(add1);

        factory.issuanceIndexTokensWithEth{value: (1e18 * 1001) / 1000}(1e18);
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
    }

    function testIssuanceWithTokens() public {
        uint256 startAmount = 1e14;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);

        usdt.approve(address(factory), 1001e18);
        factory.issuanceIndexTokens(address(usdt), 1000e18, 3000);
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
    }

    function testIssuanceWithTokensOutput() public {
        uint256 startAmount = 1e14;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);
        usdt.approve(address(factory), 1001e18);
        factory.issuanceIndexTokens(address(usdt), 1000e18, 3000);
        console.log("index token balance after isssuance", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after issuance", factoryStorage.getPortfolioBalance());
        uint256 reallOut = factory.redemption(indexToken.balanceOf(address(add1)), address(usdt), 3000);
        console.log("index token balance after redemption", indexToken.balanceOf(address(add1)));
        console.log("portfolio value after redemption", factoryStorage.getPortfolioBalance());
        console.log("real out", reallOut);
        console.log("usdt after redemption", usdt.balanceOf(add1));
    }

    ///////////////////////////////////////////////////////////////

    function testFailIssuanceWithTokensWithZeroAmount() public {
        uint256 startAmount = 0;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);

        usdt.approve(address(factory), 1001e18);
        vm.expectRevert("Invalid number");
        factory.issuanceIndexTokens(address(usdt), startAmount, 3000);

        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
    }

    function testFailIssuanceWithTokensWithAddressZero() public {
        uint256 startAmount = 1000e18;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        usdt.transfer(add1, 1001e18);
        vm.startPrank(add1);

        usdt.approve(address(factory), 1001e18);
        vm.expectRevert("Invalid address");
        factory.issuanceIndexTokens(address(0), startAmount, 3000);
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
    }

    function testFailIssuanceWithEthWithZeroAmount() public {
        uint256 startAmount = 0;

        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();
        payable(add1).transfer(11e18);
        vm.startPrank(add1);

        vm.expectRevert("Invalid Amount");
        factory.issuanceIndexTokensWithEth{value: (1e18 * 1001) / 1000}(startAmount);
        factory.redemption(indexToken.balanceOf(address(add1)), address(weth), 3);
    }

    function testAssertIssuanceWithTokensOutput() public {
        uint256 startAmount = 1001e18;
        updateOracleList();

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);

        vm.stopPrank();
        usdt.transfer(add1, startAmount);

        vm.startPrank(add1);
        usdt.approve(address(factory), startAmount);
        factory.issuanceIndexTokens(address(usdt), 1000e18, 3000);

        uint256 userUsdtBalanceBeforeRedemption = usdt.balanceOf(address(add1));
        uint256 userIndexTokenBalanceBeforeRedemption = indexToken.balanceOf(address(add1));

        uint256 reallOut = factory.redemption(indexToken.balanceOf(address(add1)), address(usdt), 3000);

        uint256 userUsdtBalanceAfterRedemption = usdt.balanceOf(address(add1));
        uint256 userIndexTokenBalanceAfterRedemption = indexToken.balanceOf(address(add1));

        assertGt(userUsdtBalanceAfterRedemption, userUsdtBalanceBeforeRedemption);
        assertLt(userIndexTokenBalanceAfterRedemption, userIndexTokenBalanceBeforeRedemption);
    }

    function testFailPauseAndUnpause() public {
        // Only the owner should be able to pause

        factory.proposeOwner(owner);
        vm.startPrank(owner);
        factory.transferOwnership(owner);
        vm.stopPrank();

        vm.startPrank(owner);
        factory.pause();
        vm.stopPrank();

        uint256 inputAmount = 10e18;
        vm.startPrank(add1);
        weth.approve(address(factory), inputAmount);
        vm.expectRevert("Pausable: paused");
        factory.issuanceIndexTokens(address(weth), inputAmount, 500);
        vm.stopPrank();

        vm.prank(owner);
        factory.unpause();
        vm.stopPrank();

        vm.startPrank(add1);
        factory.issuanceIndexTokens(address(weth), inputAmount, 500);
        vm.stopPrank();
    }
}
