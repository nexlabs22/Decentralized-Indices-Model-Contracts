// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/factory/IndexFactoryStorage.sol";
import "./OlympixUnitTest.sol";

contract IndexFactoryStorageTest is Test {
    IndexFactoryStorage indexFactoryStorage;

    address user = address(2);
    address factoryBalancer = address(3);

    function setUp() external {
        indexFactoryStorage = new IndexFactoryStorage();
        indexFactoryStorage.initialize(
            payable(address(0x1)),
            address(0x2),
            address(0x3),
            bytes32(0),
            address(0x4),
            address(0x5),
            address(0x6),
            address(0x7),
            address(0x8),
            address(0x9),
            address(0x10)
        );
    }

    function testInitializeSetsParametersCorrectly() public {
        assertEq(address(indexFactoryStorage.indexToken()), address(0x1), "IndexToken address mismatch");
        assertEq(indexFactoryStorage.externalJobId(), bytes32(0), "External job ID mismatch");
        assertEq(address(indexFactoryStorage.toUsdPriceFeed()), address(0x4), "Price feed address mismatch");
        assertEq(address(indexFactoryStorage.weth()), address(0x5), "WETH address mismatch");
        assertEq(address(indexFactoryStorage.quoter()), address(0x6), "Quoter address mismatch");
        assertEq(address(indexFactoryStorage.swapRouterV3()), address(0x7), "SwapRouterV3 address mismatch");
        assertEq(address(indexFactoryStorage.factoryV3()), address(0x8), "FactoryV3 address mismatch");
        assertEq(address(indexFactoryStorage.swapRouterV2()), address(0x9), "SwapRouterV2 address mismatch");
        assertEq(address(indexFactoryStorage.factoryV2()), address(0x10), "FactoryV2 address mismatch");

        assertEq(indexFactoryStorage.feeRate(), 10, "Fee rate mismatch");
        assertEq(indexFactoryStorage.feeReceiver(), address(this), "Fee receiver mismatch");
    }

    function testInitializeRevertsWhenCalledTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        indexFactoryStorage.initialize(
            payable(address(0x1)),
            address(0x2),
            address(0x3),
            bytes32(0),
            address(0x4),
            address(0x5),
            address(0x6),
            address(0x7),
            address(0x8),
            address(0x9),
            address(0x10)
        );
    }

    function test_setFactory_SuccessfulSetFactory() public {
        address newFactoryAddress = address(0x123);
        vm.prank(indexFactoryStorage.owner());
        indexFactoryStorage.setFactory(newFactoryAddress);
        assertEq(indexFactoryStorage.factoryAddress(), newFactoryAddress);
    }

    function testSetFactoryRevertWithNonOwnerAddress() public {
        address newFactoryAddress = address(0x123);
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setFactory(newFactoryAddress);
    }

    function test_setFactoryBalancer_SuccessfulSetFactoryBalancer() public {
        address newFactoryBalancerAddress = address(0x123);
        vm.prank(indexFactoryStorage.owner());
        indexFactoryStorage.setFactoryBalancer(newFactoryBalancerAddress);
        assertEq(indexFactoryStorage.factoryBalancerAddress(), newFactoryBalancerAddress);
    }

    function testSetFactoryBalancerRevertWithNonOwnerAddress() public {
        address newFactoryBalancerAddress = address(0x123);
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setFactoryBalancer(newFactoryBalancerAddress);
    }

    function test_setPriceFeed_FailWhenPriceFeedAddressIsZero() public {
        vm.expectRevert("ICO: Price feed address cannot be zero address");
        indexFactoryStorage.setPriceFeed(address(0));
    }

    function test_setPriceFeed_SuccessfulSetPriceFeed() public {
        address newPriceFeed = address(0x123);
        vm.prank(indexFactoryStorage.owner());
        indexFactoryStorage.setPriceFeed(newPriceFeed);
        assertEq(address(indexFactoryStorage.toUsdPriceFeed()), newPriceFeed);
    }

    function testSetPriceFeedRevertWithNonOwnerAddress() public {
        address newPriceFeed = address(0x123);
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setPriceFeed(newPriceFeed);
    }

    function testSetVaultSuccessful() public {
        address newVault = address(0x123);
        vm.startPrank(indexFactoryStorage.owner());
        indexFactoryStorage.setVault(newVault);
        assertEq(address(indexFactoryStorage.vault()), newVault);
    }

    function testSetVaultRevertWithNonOwnerAddress() public {
        address newVault = address(0x123);
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setVault(newVault);
    }

    function testSetPriceOracleSuccessful() public {
        address newPriceOracle = address(0x123);
        vm.startPrank(indexFactoryStorage.owner());
        indexFactoryStorage.setPriceOracle(newPriceOracle);
        assertEq(address(indexFactoryStorage.priceOracle()), newPriceOracle);
    }

    function testSetPriceOracleRevertWithNonOwnerAddress() public {
        address newPriceOracle = address(0x123);
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setPriceOracle(newPriceOracle);
    }

    function testSetUrlByOwner() public {
        string memory beforeAddress = "https://example.com/";
        string memory afterAddress = "api/endpoint";

        indexFactoryStorage.setUrl(beforeAddress, afterAddress);
    }

    function testSetUrlRevertsForNonOwner() public {
        string memory beforeAddress = "https://example.com/";
        string memory afterAddress = "api/endpoint";

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setUrl(beforeAddress, afterAddress);
    }

    function testSetFeeRateByOwner() public {
        vm.warp(block.timestamp + 13 hours);

        uint8 newFee = 50;

        indexFactoryStorage.setFeeRate(newFee);

        assertEq(indexFactoryStorage.feeRate(), newFee, "Fee rate was not updated correctly");
        assertEq(indexFactoryStorage.latestFeeUpdate(), block.timestamp, "Latest fee update timestamp not updated");
    }

    function testSetFeeRateRevertsIfTooSoon() public {
        uint8 newFee = 50;

        vm.warp(block.timestamp + 10 hours);

        vm.expectRevert("You should wait at least 12 hours after the latest update");
        indexFactoryStorage.setFeeRate(newFee);
    }

    function testSetFeeRateRevertsForNonOwner() public {
        uint8 newFee = 50;

        vm.warp(block.timestamp + 13 hours);

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setFeeRate(newFee);
    }

    function testSetFeeReceiverSuccessful() public {
        address newFeeReceiver = address(0x123);
        vm.startPrank(indexFactoryStorage.owner());
        indexFactoryStorage.setFeeReceiver(newFeeReceiver);
        assertEq(address(indexFactoryStorage.feeReceiver()), newFeeReceiver);
    }

    function testSetFeeReceiverRevertWithNonOwnerAddress() public {
        address newFeeReceiver = address(0x123);
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.setFeeReceiver(newFeeReceiver);
    }

    function testUpdateCurrentListByFactory() public {
        vm.prank(indexFactoryStorage.owner());

        indexFactoryStorage.setFactoryBalancer(factoryBalancer);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);

        uint256[] memory marketShares = new uint256[](2);
        marketShares[0] = 100;
        marketShares[1] = 200;

        uint24[] memory swapFees = new uint24[](2);
        swapFees[0] = 300;
        swapFees[1] = 400;

        indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);

        vm.prank(factoryBalancer);
        indexFactoryStorage.updateCurrentList();

        assertEq(indexFactoryStorage.totalCurrentList(), 2, "Total current list not updated correctly");

        assertEq(indexFactoryStorage.currentList(0), address(tokens[0]), "First token not updated correctly");
        assertEq(
            indexFactoryStorage.tokenCurrentMarketShare(address(tokens[0])),
            100,
            "Market share not updated for first token"
        );

        assertEq(indexFactoryStorage.currentList(1), address(tokens[1]), "Second token not updated correctly");
        assertEq(
            indexFactoryStorage.tokenCurrentMarketShare(address(tokens[1])),
            200,
            "Market share not updated for second token"
        );
    }

    function testUpdateCurrentListRevertsForNonFactory() public {
        vm.prank(user);
        vm.expectRevert("Caller is not a factory contract");
        indexFactoryStorage.updateCurrentList();
    }

    function test_priceInWei_SuccessfulPriceInWei() public {
        int256 price = 100000000;
        uint8 decimals = 8;

        vm.mockCall(
            address(indexFactoryStorage.toUsdPriceFeed()),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, 0, 0)
        );

        vm.mockCall(
            address(indexFactoryStorage.toUsdPriceFeed()),
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        uint256 expectedPriceInWei = uint256(price) * 10 ** (18 - decimals);
        uint256 actualPriceInWei = indexFactoryStorage.priceInWei();

        assertEq(actualPriceInWei, expectedPriceInWei);
    }

    function test_setFeeRate_FailWhenLatestFeeUpdateIsLessThan12Hours() public {
        vm.expectRevert("You should wait at least 12 hours after the latest update");
        indexFactoryStorage.setFeeRate(50);
    }

    function test_concatenation_SuccessfulConcatenation() public {
        string memory a = "Hello, ";
        string memory b = "World!";
        string memory result = indexFactoryStorage.concatenation(a, b);
        assertEq(result, "Hello, World!");
    }

    function test_mockFillAssetsList_SuccessfulFill() public {
        vm.prank(indexFactoryStorage.owner());

        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);

        uint256[] memory marketShares = new uint256[](2);
        marketShares[0] = 100;
        marketShares[1] = 200;

        uint24[] memory swapFees = new uint24[](2);
        swapFees[0] = 300;
        swapFees[1] = 400;

        indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);

        assertEq(indexFactoryStorage.totalOracleList(), 2);
        assertEq(indexFactoryStorage.totalCurrentList(), 2);
        assertEq(indexFactoryStorage.lastUpdateTime(), block.timestamp);

        assertEq(indexFactoryStorage.oracleList(0), address(0x1));
        assertEq(indexFactoryStorage.oracleList(1), address(0x2));

        assertEq(indexFactoryStorage.tokenOracleListIndex(address(0x1)), 0);
        assertEq(indexFactoryStorage.tokenOracleListIndex(address(0x2)), 1);

        assertEq(indexFactoryStorage.tokenOracleMarketShare(address(0x1)), 100);
        assertEq(indexFactoryStorage.tokenOracleMarketShare(address(0x2)), 200);

        assertEq(indexFactoryStorage.tokenSwapFee(address(0x1)), 300);
        assertEq(indexFactoryStorage.tokenSwapFee(address(0x2)), 400);

        assertEq(indexFactoryStorage.currentList(0), address(0x1));
        assertEq(indexFactoryStorage.currentList(1), address(0x2));

        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x1)), 100);
        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x2)), 200);

        assertEq(indexFactoryStorage.tokenCurrentListIndex(address(0x1)), 0);
        assertEq(indexFactoryStorage.tokenCurrentListIndex(address(0x2)), 1);
    }

    function testMockFillAssetsList_RevertWithNonOwnerAddress() public {
        vm.prank(user);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);

        uint256[] memory marketShares = new uint256[](2);
        marketShares[0] = 100;
        marketShares[1] = 200;

        uint24[] memory swapFees = new uint24[](2);
        swapFees[0] = 300;
        swapFees[1] = 400;

        vm.expectRevert("Ownable: caller is not the owner");
        indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);
    }

    function test_mockFillAssetsList_FillWhenTotalCurrentListIsNotZero() public {
        vm.prank(indexFactoryStorage.owner());

        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);

        uint256[] memory marketShares = new uint256[](2);
        marketShares[0] = 100;
        marketShares[1] = 200;

        uint24[] memory swapFees = new uint24[](2);
        swapFees[0] = 300;
        swapFees[1] = 400;

        indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);

        address[] memory newTokens = new address[](2);
        newTokens[0] = address(0x3);
        newTokens[1] = address(0x4);

        uint256[] memory newMarketShares = new uint256[](2);
        newMarketShares[0] = 300;
        newMarketShares[1] = 400;

        uint24[] memory newSwapFees = new uint24[](2);
        newSwapFees[0] = 500;
        newSwapFees[1] = 600;

        indexFactoryStorage.mockFillAssetsList(newTokens, newMarketShares, newSwapFees);

        assertEq(indexFactoryStorage.totalOracleList(), 2);
        assertEq(indexFactoryStorage.totalCurrentList(), 2);
        assertEq(indexFactoryStorage.lastUpdateTime(), block.timestamp);

        assertEq(indexFactoryStorage.oracleList(0), address(0x3));
        assertEq(indexFactoryStorage.oracleList(1), address(0x4));

        assertEq(indexFactoryStorage.tokenOracleListIndex(address(0x3)), 0);
        assertEq(indexFactoryStorage.tokenOracleListIndex(address(0x4)), 1);

        assertEq(indexFactoryStorage.tokenOracleMarketShare(address(0x3)), 300);
        assertEq(indexFactoryStorage.tokenOracleMarketShare(address(0x4)), 400);

        assertEq(indexFactoryStorage.tokenSwapFee(address(0x3)), 500);
        assertEq(indexFactoryStorage.tokenSwapFee(address(0x4)), 600);

        assertEq(indexFactoryStorage.currentList(0), address(0x1));
        assertEq(indexFactoryStorage.currentList(1), address(0x2));

        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x1)), 100);
        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x2)), 200);

        assertEq(indexFactoryStorage.tokenCurrentListIndex(address(0x1)), 0);
        assertEq(indexFactoryStorage.tokenCurrentListIndex(address(0x2)), 1);
    }

    function test_updateCurrentList_SuccessfulUpdate() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);

        uint256[] memory marketShares = new uint256[](2);
        marketShares[0] = 50;
        marketShares[1] = 50;

        uint24[] memory swapFees = new uint24[](2);
        swapFees[0] = 3000;
        swapFees[1] = 3000;

        indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);

        vm.prank(indexFactoryStorage.factoryAddress());
        indexFactoryStorage.updateCurrentList();

        assertEq(indexFactoryStorage.totalCurrentList(), 2);
        assertEq(indexFactoryStorage.currentList(0), address(0x1));
        assertEq(indexFactoryStorage.currentList(1), address(0x2));
        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x1)), 50);
        assertEq(indexFactoryStorage.tokenCurrentMarketShare(address(0x2)), 50);
    }

    function test_getAmountOut_SuccessfulGetAmountOut() public {
        address tokenIn = address(0x1);
        address tokenOut = address(0x2);
        uint256 amountIn = 1 ether;
        uint24 swapFee = 3000;

        address priceOracle = address(0x3);
        address factoryV3 = address(0x4);

        vm.mockCall(
            priceOracle,
            abi.encodeWithSelector(
                IPriceOracle.estimateAmountOut.selector, factoryV3, tokenIn, tokenOut, uint128(amountIn), swapFee
            ),
            abi.encode(2 ether)
        );

        indexFactoryStorage.setPriceOracle(priceOracle);

        uint256 amountOut = indexFactoryStorage.getAmountOut(tokenIn, tokenOut, amountIn, swapFee);

        //    assertEq(amountOut, 2 ether);
    }

    function test_getAmountOut_FailWhenAmountInIsZero() public {
        indexFactoryStorage.getAmountOut(address(0x1), address(0x2), 0, 0);
    }

    function test_setFeeRate_FailWhenNewFeeIsGreaterThan100() public {
        vm.warp(block.timestamp + 13 hours);
        vm.expectRevert("The newFee should be between 1 and 100 (0.01% - 1%)");
        indexFactoryStorage.setFeeRate(101);
    }

    // function test_getPortfolioBalance_SuccessfulGetPortfolioBalance() public {
    //     address[] memory tokens = new address[](2);
    //     tokens[0] = address(0x1);
    //     tokens[1] = address(0x2);

    //     uint256[] memory marketShares = new uint256[](2);
    //     marketShares[0] = 50;
    //     marketShares[1] = 50;

    //     uint24[] memory swapFees = new uint24[](2);
    //     swapFees[0] = 3000;
    //     swapFees[1] = 3000;

    //     indexFactoryStorage.mockFillAssetsList(tokens, marketShares, swapFees);

    //     address tokenIn = address(0x2);
    //     address tokenOut = address(indexFactoryStorage.weth());
    //     uint256 amountIn = 1 ether;
    //     uint24 swapFee = 3000;

    //     address priceOracle = address(0x3);
    //     address factoryV3 = address(0x4);

    //     vm.mockCall(
    //         priceOracle,
    //         abi.encodeWithSelector(
    //             IPriceOracle.estimateAmountOut.selector, factoryV3, tokenIn, tokenOut, uint128(amountIn), swapFee
    //         ),
    //         abi.encode(2 ether)
    //     );

    //     indexFactoryStorage.setPriceOracle(priceOracle);

    //     vm.mockCall(
    //         tokenIn,
    //         abi.encodeWithSelector(IERC20.balanceOf.selector, address(indexFactoryStorage.indexToken())),
    //         abi.encode(amountIn)
    //     );

    //     vm.mockCall(
    //         tokens[0],
    //         abi.encodeWithSelector(IERC20.balanceOf.selector, address(indexFactoryStorage.indexToken())),
    //         abi.encode(0)
    //     );

    //     uint256 portfolioBalance = indexFactoryStorage.getPortfolioBalance();

    //     assertEq(portfolioBalance, 2 ether);
    // }
}
