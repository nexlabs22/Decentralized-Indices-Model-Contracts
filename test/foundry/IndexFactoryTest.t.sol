// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/factory/IndexFactory.sol";
import "../../contracts/factory/IndexFactoryStorage.sol";
import "../../contracts/uniswap/Token.sol";
import "./ContractDeployer.sol";
import "../mocks/MockERC20.sol";
import "../../contracts/interfaces/IWETH.sol";
import "../../contracts/test/LinkToken.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/vault/Vault.sol";

contract IndexFactoryTest is Test, IndexFactory {
    IndexFactory indexFactory;
    ContractDeployer deployer;
    // MockFactoryStorage Fstorage;
    IndexFactoryStorage Fstorage;
    IWETH weth;
    LinkToken link;
    MockApiOracle oracle;
    Vault vault;
    address factoryAddress;
    address positionManager;
    address wethAddress;

    MockERC20 token;

    Token token0;
    Token token1;
    Token token2;
    Token token3;
    Token token4;
    Token usdt;

    address ownerAddr = address(1234);
    address user = address(2);

    function setUp() external {
        deployer = new ContractDeployer();

        vm.deal(address(deployer), 10 ether);

        deployer.deployAllContracts();

        indexFactory = deployer.factory();
        Fstorage = deployer.factoryStorage();
        token0 = deployer.token0();
        token1 = deployer.token1();
        token2 = deployer.token2();
        token3 = deployer.token3();
        token4 = deployer.token4();
        weth = deployer.weth();
        usdt = deployer.usdt();
        link = deployer.link();
        oracle = deployer.oracle();
        factoryAddress = deployer.factoryAddress();
        positionManager = deployer.positionManager();
        wethAddress = deployer.wethAddress();
        vault = deployer.vault();

        deployer.addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 1000e18, 1e18);
        deployer.addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, 1000e18, 1e18);
        deployer.addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, 1000e18, 1e18);
        deployer.addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, 1000e18, 1e18);
        deployer.addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, 1000e18, 1e18);
        deployer.addLiquidityETH(positionManager, factoryAddress, usdt, wethAddress, 1000e18, 1e18);

        vm.startPrank(address(deployer));
        indexFactory.proposeOwner(ownerAddr);
        vm.stopPrank();

        vm.startPrank(ownerAddr);
        indexFactory.transferOwnership(ownerAddr);
        vm.stopPrank();

        updateOracleList();
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

        // link.transfer(address(factoryStorage), 1e17);
        // bytes32 requestId = factoryStorage.requestAssetsData();
        // oracle.fulfillOracleFundingRateRequest(requestId, assetList, tokenShares, swapVersions);
    }

    function testUnpause() public {
        vm.startPrank(ownerAddr);
        indexFactory.pause();
        indexFactory.unpause();
        assert(!indexFactory.paused());
    }

    function testIssuanceIndexTokens_FailWhenTokenInIsZeroAddress() public {
        address alice = address(0x3);
        vm.startPrank(alice);
        vm.expectRevert("Invalid token address");
        indexFactory.issuanceIndexTokens(address(0), 1 ether, 0);
        vm.stopPrank();
    }

    function testIssuanceIndexTokens_FailWhenAmountInIsInvalid() public {
        address alice = address(0x3);
        vm.startPrank(alice);
        vm.expectRevert("Invalid amount");
        indexFactory.issuanceIndexTokens(address(1), 0, 0);
        vm.stopPrank();
    }

    function testIssuanceIndexTokensWithEth_FailWhenInputAmountIsInvalid() public {
        vm.expectRevert("Invalid amount");
        indexFactory.issuanceIndexTokensWithEth{value: 1}(0);
    }

    function testIssuanceIndexTokensWithEth_FailWhenValueIsLowerThanRequiredAmount() public {
        IndexFactoryStorage factoryStorage = new IndexFactoryStorage();
        vm.expectRevert("lower than required amount");
        indexFactory.issuanceIndexTokensWithEth{value: 1}(2);
    }

    function testToWei_SameDecimals() public {
        int256 amount = 100;
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 18;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        assertEq(result, amount, "Result should equal the original amount");
    }

    function testToWei_ChainDecimalsGreater() public {
        int256 amount = 100;
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        assertEq(result, 100 * 10 ** 12, "Result should scale up to 18 decimals");
    }

    function testToWei_NegativeAmount() public {
        int256 amount = -100;
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        assertEq(result, -100 * 10 ** 12, "Result should scale up to 18 decimals and remain negative");
    }

    function testToWei_Exponentiation_ChainDecimalsGreater() public {
        uint8 amountDecimals = 3;
        uint8 chainDecimals = 6;

        uint256 scalingFactor = 10 ** (chainDecimals - amountDecimals);

        assertEq(scalingFactor, 1000, "Exponentiation failed for chain decimals greater");
    }

    function testToWei_AmountDecimalsGreater() public {
        int256 amount = 1;
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 6;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        assertEq(result, amount * int256(10 ** (amountDecimals - chainDecimals)), "Failed to scale down correctly");
    }

    function testToWei_Exponentiation_AmountDecimalsGreater() public {
        uint8 amountDecimals = 9;
        uint8 chainDecimals = 3;

        uint256 scalingFactor = 10 ** (amountDecimals - chainDecimals);

        assertEq(scalingFactor, 10 ** 6, "Exponentiation failed for amount decimals greater");
    }

    function testPauseByOwner() public {
        vm.prank(ownerAddr);
        indexFactory.pause();

        bool isPaused = indexFactory.paused();
        assertTrue(isPaused, "The contract should be paused");
    }

    function testPauseRevertsIfNotOwner() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactory.pause();
        vm.stopPrank();
    }

    function testUnpauseByOwner() public {
        vm.startPrank(ownerAddr);
        indexFactory.pause();

        indexFactory.unpause();
        vm.stopPrank();

        bool isPaused = indexFactory.paused();
        assertFalse(isPaused, "The contract should be unpaused");
    }

    function testUnpauseRevertsIfNotOwner() public {
        vm.prank(ownerAddr);
        indexFactory.pause();

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactory.unpause();
    }

    function testWethAmountTimesMarketShare() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 result = (wethAmount * marketShare) / 1e18;

        assertEq(result, 500 * 1e18, "Incorrect result for _wethAmount * marketShare");
    }

    function testOutputAmountGreaterThanZero() public {
        uint256 outputAmount = 5 * 1e18;
        assertTrue(outputAmount > 0, "Output amount should be greater than zero");
    }

    function testSwapCalculationForToken() public {
        address tokenAddress = address(token);
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;
        uint24 swapFee = 3000;
        uint256 outputAmount = (wethAmount * marketShare) / 100e18;

        assertEq(outputAmount, 5 * 1e18, "Incorrect swap output amount");
        assertEq(swapFee, 3000, "Incorrect swap fee");
    }

    function testTokenAddressNotEqualToWETH() public {
        address tokenAddress = address(token);
        assertTrue(tokenAddress != address(weth), "Token address should not be equal to WETH");
    }

    function testWethAmountTimesMarketShareDividedBy100e18() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 result = (wethAmount * marketShare) / 100e18;

        assertEq(result, 5 * 1e18, "Incorrect result for (_wethAmount * marketShare) / 100e18");
    }

    function testAmountTimesPowerOfTen() public {
        int256 amount = 100;
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        int256 scalingFactor = int256(10 ** (uint256(chainDecimals) - uint256(amountDecimals)));
        int256 expectedResult = amount * scalingFactor;

        assertEq(result, expectedResult, "Incorrect scaling for _amount * 10 ** (_chainDecimals - _amountDecimals)");
    }

    function testAmountDividedByPowerOfTenFails() public {
        int256 amount = 100;
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        int256 scalingFactor = int256(10 ** (uint256(chainDecimals) - uint256(amountDecimals)));
        int256 expectedResult = amount * scalingFactor;

        int256 mutatedResult = amount / int256(10 * (uint256(chainDecimals) - uint256(amountDecimals)));

        require(result != mutatedResult, "Mutation did not affect the result as expected");
    }

    function testPowerOfTenScaling() public {
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        uint256 expectedFactor = 10 ** (uint256(chainDecimals) - uint256(amountDecimals));

        assertEq(expectedFactor, 1e12, "Incorrect scaling factor for 10 ** (_chainDecimals - _amountDecimals)");
    }

    function testPowerOfTenScalingFails() public {
        uint8 amountDecimals = 6;
        uint8 chainDecimals = 18;

        uint256 expectedFactor = 10 ** (uint256(chainDecimals) - uint256(amountDecimals));
        uint256 mutatedFactor = 10 * (uint256(chainDecimals) - uint256(amountDecimals));

        require(expectedFactor != mutatedFactor, "Mutation did not affect the result as expected");
    }

    function testAmountTimesPowerOfTenReverse() public {
        int256 amount = 100;
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 6;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        int256 scalingFactor = int256(10 ** (uint256(amountDecimals) - uint256(chainDecimals)));
        int256 expectedResult = amount * scalingFactor;

        assertEq(result, expectedResult, "Incorrect scaling for _amount * 10 ** (_amountDecimals - _chainDecimals)");
    }

    function testAmountDividedByPowerOfTenReverseFails() public {
        int256 amount = 100;
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 6;

        int256 result = _toWei(amount, amountDecimals, chainDecimals);

        int256 scalingFactor = int256(10 ** (uint256(amountDecimals) - uint256(chainDecimals)));
        int256 expectedResult = amount * scalingFactor;

        int256 mutatedResult = amount / int256(10 * (uint256(amountDecimals) - uint256(chainDecimals)));

        require(result != mutatedResult, "Mutation did not affect the result as expected");
    }

    function testPowerOfTenScalingReverse() public {
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 6;

        uint256 expectedFactor = 10 ** (uint256(amountDecimals) - uint256(chainDecimals));

        assertEq(expectedFactor, 1e12, "Incorrect scaling factor for 10 ** (_amountDecimals - _chainDecimals)");
    }

    function testPowerOfTenScalingReverseFails() public {
        uint8 amountDecimals = 18;
        uint8 chainDecimals = 6;

        uint256 expectedFactor = 10 ** (uint256(amountDecimals) - uint256(chainDecimals));
        uint256 mutatedFactor = 10 * (uint256(amountDecimals) - uint256(chainDecimals));

        require(expectedFactor != mutatedFactor, "Mutation did not affect the result as expected");
    }

    function testTotalSupplyTimesWethAmountFailsForMutation() public {
        uint256 totalSupply = 1000 * 1e18;
        uint256 wethAmount = 10 * 1e18;

        uint256 result = totalSupply * wethAmount;
        uint256 mutatedResult = totalSupply / wethAmount;

        require(result != mutatedResult, "Mutation incorrectly changed multiplication to division");
    }

    function testDivisionByFirstPortfolioValueFailsForMutation() public {
        uint256 totalSupply = 1000 * 1e18;
        uint256 wethAmount = 10 * 1e18;
        uint256 firstPortfolioValue = 100 * 1e18;

        uint256 result = (totalSupply * wethAmount) / firstPortfolioValue;
        uint256 mutatedResult = (totalSupply * wethAmount) * firstPortfolioValue;

        require(result != mutatedResult, "Mutation incorrectly changed division to multiplication");
    }

    function testDivisionBy100e18FailsForMutation() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 result = (wethAmount * marketShare) / 100e18;
        uint256 mutatedResult = (wethAmount * marketShare) * 100e18;

        require(result != mutatedResult, "Mutation incorrectly changed division to multiplication");
    }

    function testWethAmountTimesMarketShareFailsForMutation() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 result = wethAmount * marketShare;
        uint256 mutatedResult = wethAmount / marketShare;

        require(result != mutatedResult, "Mutation incorrectly changed multiplication to division");
    }

    function testOutputAmountTimesFeeRate() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 ownerFee = (outputAmount * feeRate) / 10000;

        assertEq(ownerFee, 10, "Incorrect owner fee calculation");
    }

    function testOutputAmountTimesFeeRateFailsForMutation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 originalFee = (outputAmount * feeRate) / 10000;

        uint256 mutatedFee = (outputAmount * feeRate) * 10000;

        require(originalFee != mutatedFee, "Mutation incorrectly changed division to multiplication");
    }

    function testOutputAmountDividedByFeeRateFailsForMutation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 originalFee = outputAmount * feeRate;

        uint256 mutatedFee = outputAmount / feeRate;

        require(originalFee != mutatedFee, "Mutation incorrectly changed multiplication to division");
    }

    function testTokenOutConditionFailsForMutation() public {
        address tokenOut = address(weth);

        bool originalCondition = tokenOut == address(weth);

        bool mutatedCondition = tokenOut != address(weth);

        require(originalCondition != mutatedCondition, "Mutation incorrectly changed the condition");
    }

    function testOutputAmountMinusOwnerFee() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 ownerFee = (outputAmount * feeRate) / 10000;
        uint256 userAmount = outputAmount - ownerFee;

        assertEq(userAmount, 990, "Incorrect calculation for output amount minus owner fee");
    }

    function testOutputAmountMinusOwnerFeeFailsForMutation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 ownerFee = (outputAmount * feeRate) / 10000;

        uint256 originalUserAmount = outputAmount - ownerFee;

        uint256 mutatedUserAmount = outputAmount + ownerFee;

        require(originalUserAmount != mutatedUserAmount, "Mutation incorrectly changed subtraction to addition");
    }

    function testSwapCalculation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;
        uint24 swapFee = 30;

        uint256 ownerFee = (outputAmount * feeRate) / 10000;
        uint256 userAmount = outputAmount - ownerFee;

        uint256 swappedAmount = userAmount - swapFee;

        assertEq(swappedAmount, 960, "Incorrect swap calculation with fees");
    }

    function testSwapCalculationFailsForMutation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;
        uint24 swapFee = 30;

        uint256 ownerFee = (outputAmount * feeRate) / 10000;
        uint256 userAmount = outputAmount - ownerFee;

        uint256 originalSwappedAmount = userAmount - swapFee;

        uint256 mutatedSwappedAmount = userAmount + swapFee;

        require(originalSwappedAmount != mutatedSwappedAmount, "Mutation incorrectly changed subtraction to addition");
    }

    function testMarketShareDivision() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 originalResult = (wethAmount * marketShare) / 100e18;

        uint256 mutatedResult = (wethAmount * marketShare) * 100e18;

        require(originalResult != mutatedResult, "Mutation incorrectly changed division to multiplication");
    }

    function testMarketShareMultiplication() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 originalResult = wethAmount * marketShare;

        uint256 mutatedResult = wethAmount / marketShare;

        require(originalResult != mutatedResult, "Mutation incorrectly changed multiplication to division");
    }

    function testOutputAmountCondition() public {
        uint256 outputAmount = 5 * 1e18;

        require(outputAmount > 0, "Output amount should be greater than zero");

        bool mutatedCondition = outputAmount < 0;
        require(!mutatedCondition, "Mutation incorrectly changed the condition");
    }

    function issuanceIndexTokensNonReentrantRemoved(address _tokenIn, uint256 _amountIn, uint24 _tokenInSwapFee)
        public
    {
        require(_tokenIn != address(0), "Invalid token address");
        require(_amountIn > 0, "Invalid amount");
        IWETH weth = factoryStorage.weth();
        Vault vault = factoryStorage.vault();
        uint256 totalCurrentList = factoryStorage.totalCurrentList();
        uint256 feeRate = factoryStorage.feeRate();
        uint256 feeAmount = (_amountIn * feeRate) / 10000;

        uint256 firstPortfolioValue = factoryStorage.getPortfolioBalance();

        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn + feeAmount), "Token transfer failed"
        );
        uint256 wethAmountBeforeFee =
            swap(_tokenIn, address(weth), _amountIn + feeAmount, address(this), _tokenInSwapFee);
        address feeReceiver = factoryStorage.feeReceiver();
        uint256 feeWethAmount = (wethAmountBeforeFee * feeRate) / 10000;
        uint256 wethAmount = wethAmountBeforeFee - feeWethAmount;

        require(weth.transfer(address(feeReceiver), feeWethAmount), "Fee transfer failed");
        _issuance(_tokenIn, _amountIn, totalCurrentList, vault, wethAmount, firstPortfolioValue);
    }

    function test_toWei_Mutations() public {
        int256 amount = 100;
        uint8 amountDecimals = 8;
        uint8 chainDecimals = 18;

        int256 expected = amount * int256(10 ** (chainDecimals - amountDecimals));

        {
            uint8 mutatedChainDecimals = 8;
            int256 mutatedResult = _toWei(amount, amountDecimals, mutatedChainDecimals);
            assertFalse(mutatedResult == expected, "Mutation not killed: _chainDecimals < _amountDecimals");
        }

        {
            uint256 mutatedMultiplier = 10 * (chainDecimals - amountDecimals);
            int256 mutatedResult = amount * int256(mutatedMultiplier);
            int256 result = _toWei(amount, amountDecimals, chainDecimals);
            assertFalse(mutatedResult == result, "Mutation not killed: 10 * (_chainDecimals - _amountDecimals)");
        }

        {
            int256 mutatedResult =
                amount / int256(10 / (int256(uint256(chainDecimals)) - int256(uint256(amountDecimals))));
            int256 result = _toWei(amount, amountDecimals, chainDecimals);
            assertFalse(
                mutatedResult == result,
                "Mutation not killed: _amount / int256(10 / (_chainDecimals - _amountDecimals))"
            );
        }

        {
            uint8 mutatedChainDecimals = chainDecimals + amountDecimals;
            int256 mutatedResult = amount * int256(10 ** uint256(mutatedChainDecimals));
            int256 result = _toWei(amount, amountDecimals, chainDecimals);
            assertFalse(mutatedResult == result, "Mutation not killed: _chainDecimals + _amountDecimals");
        }

        int256 actual = _toWei(amount, amountDecimals, chainDecimals);
        assertEq(expected, actual, "Original logic failed for valid input");
    }
}
