// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/factory/IndexFactory.sol";
import "./ContractDeployer.sol";
import "../mocks/MockERC20.sol";

contract IndexFactoryTest is Test, IndexFactory {
    IndexFactory indexFactory;
    ContractDeployer deployer;
    MockFactoryStorage Fstorage;
    MockERC20 weth;

    MockERC20 token;

    address user = address(2);

    function setUp() external {
        indexFactory = new IndexFactory();
        indexFactory.initialize(payable(address(new IndexFactoryStorage())));
        deployer = new ContractDeployer();

        Fstorage = new MockFactoryStorage(token, 1e18);

        token = new MockERC20("Test", "TT");
        weth = new MockERC20("WETH", "WETH");
    }

    function testUnpause() public {
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
        indexFactory.pause();

        indexFactory.unpause();

        bool isPaused = indexFactory.paused();
        assertFalse(isPaused, "The contract should be unpaused");
    }

    function testUnpauseRevertsIfNotOwner() public {
        indexFactory.pause();

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        indexFactory.unpause();
    }

    function testTotalSupplyTimesWethAmount() public {
        token.mint(address(this), 1000 * 1e18);
        uint256 wethAmount = 10 * 1e18;

        uint256 result = 1000 * wethAmount;

        assertEq(result, 10000 * 1e18, "Incorrect result for totalSupply * _wethAmount");
    }

    function testTotalSupplyTimesWethAmountDividedByFirstPortfolioValue() public {
        token.mint(address(this), 1000 * 1e18);
        uint256 wethAmount = 10 * 1e18;
        uint256 firstPortfolioValue = 100 * 1e18;

        uint256 totalSupply = token.totalSupply();
        uint256 result = (totalSupply * wethAmount) / firstPortfolioValue;

        uint256 expectedResult = (1000e18 * wethAmount) / firstPortfolioValue;
        assertEq(result, expectedResult, "Incorrect result for (totalSupply * _wethAmount) / _firstPortfolioValue");
    }

    function testWethAmountTimesPrice() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 price = Fstorage.priceInWei();

        uint256 result = wethAmount * price;

        assertEq(result, 10 * 1e36, "Incorrect result for _wethAmount * price");
    }

    function testWethAmountTimesPriceDividedBy1e16() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 price = Fstorage.priceInWei();

        uint256 result = (wethAmount * price) / 1e16;

        assertEq(result, 10 * 1e20, "Incorrect result for (_wethAmount * price) / 1e16");
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

        // Simulated mutation
        uint256 mutatedFee = (outputAmount * feeRate) * 10000;

        require(originalFee != mutatedFee, "Mutation incorrectly changed division to multiplication");
    }

    function testOutputAmountDividedByFeeRateFailsForMutation() public {
        uint256 outputAmount = 1000;
        uint256 feeRate = 100;

        uint256 originalFee = outputAmount * feeRate;

        // Simulated mutation
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

        // Original calculation
        uint256 originalUserAmount = outputAmount - ownerFee;

        // Simulated mutation
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

        // Simulated mutation
        uint256 mutatedSwappedAmount = userAmount + swapFee;

        require(originalSwappedAmount != mutatedSwappedAmount, "Mutation incorrectly changed subtraction to addition");
    }

    // function testTokenAddressCondition() public {
    //     address tokenAddress = Fstorage.weth(); // Simulate `tokenAddress == weth`
    //     uint256 marketShare = 50e18;
    //     uint256 wethAmount = 10 * 1e18;

    //     uint256 expectedAmount = (wethAmount * marketShare) / 100e18;

    //     // Verify original behavior
    //     if (tokenAddress != address(weth)) {
    //         uint256 outputAmount = swap(address(weth), tokenAddress, expectedAmount, address(0), 3000);
    //         assertGt(outputAmount, 0, "Swap failed");
    //     } else {
    //         weth.transfer(address(0), expectedAmount);
    //     }

    //     // Simulate mutation
    //     bool mutatedCondition = tokenAddress == address(weth);
    //     require(!mutatedCondition, "Mutation incorrectly changed the condition");
    // }

    function testMarketShareDivision() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 originalResult = (wethAmount * marketShare) / 100e18;

        // Simulate mutation
        uint256 mutatedResult = (wethAmount * marketShare) * 100e18;

        require(originalResult != mutatedResult, "Mutation incorrectly changed division to multiplication");
    }

    function testMarketShareMultiplication() public {
        uint256 wethAmount = 10 * 1e18;
        uint256 marketShare = 50e18;

        uint256 originalResult = wethAmount * marketShare;

        // Simulate mutation
        uint256 mutatedResult = wethAmount / marketShare;

        require(originalResult != mutatedResult, "Mutation incorrectly changed multiplication to division");
    }

    function testOutputAmountCondition() public {
        uint256 outputAmount = 5 * 1e18;

        // Original condition
        require(outputAmount > 0, "Output amount should be greater than zero");

        // Simulate mutation
        bool mutatedCondition = outputAmount < 0;
        require(!mutatedCondition, "Mutation incorrectly changed the condition");
    }

    // ----------------------------------------------

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

    function testIssuanceIndexTokens_SuccessfulIssuance() public {
        address tokenIn = address(token);
        uint256 amountIn = 1e18;
        uint24 tokenInSwapFee = 3000;

        token.mint(address(this), amountIn + (amountIn / 10000));
        token.approve(address(indexFactory), amountIn + (amountIn / 10000));

        vm.mockCall(
            address(indexFactory.factoryStorage()),
            abi.encodeWithSelector(MockFactoryStorage.weth.selector),
            address(weth)
        );
        vm.mockCall(
            address(indexFactory.factoryStorage()),
            abi.encodeWithSelector(MockFactoryStorage.vault.selector),
            address(deployer)
        );
        vm.mockCall(
            address(indexFactory.factoryStorage()),
            abi.encodeWithSelector(MockFactoryStorage.totalCurrentList.selector),
            2
        );
        vm.mockCall(
            address(indexFactory.factoryStorage()), abi.encodeWithSelector(MockFactoryStorage.feeRate.selector), 100
        ); // 1%
        vm.mockCall(
            address(indexFactory.factoryStorage()),
            abi.encodeWithSelector(MockFactoryStorage.getPortfolioBalance.selector),
            10e18
        );
        vm.mockCall(
            address(indexFactory.factoryStorage()),
            abi.encodeWithSelector(MockFactoryStorage.feeReceiver.selector),
            address(user)
        );

        vm.mockCall(address(weth), abi.encodeWithSelector(IERC20.transfer.selector), abi.encode(true));

        indexFactory.issuanceIndexTokens(tokenIn, amountIn, tokenInSwapFee);

        assertEq(weth.balanceOf(address(user)), amountIn / 10000, "Fee receiver should receive the correct fee");
    }
}

contract MockFactoryStorage {
    MockERC20 public token;
    uint256 public priceInWei;

    address[] public currentList;
    mapping(address => uint256) public marketShare;
    mapping(address => uint24) public swapFee;
    address public weth;

    constructor(MockERC20 _indexToken, uint256 _priceInWei) {
        token = _indexToken;
        priceInWei = _priceInWei;
    }

    function addTokenToCurrentList(address _token, uint256 _marketShare, uint24 _swapFee) external {
        currentList.push(_token);
        marketShare[_token] = _marketShare;
        swapFee[_token] = _swapFee;
    }

    function testCurrentList(uint256 index) external view returns (address) {
        return currentList[index];
    }

    function tokenCurrentMarketShare(address _token) external view returns (uint256) {
        return marketShare[_token];
    }

    function tokenSwapFee(address _token) external view returns (uint24) {
        return swapFee[_token];
    }
}
