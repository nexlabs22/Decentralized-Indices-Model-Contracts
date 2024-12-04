// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/libraries/OracleLibrary.sol";
import "../../contracts/interfaces/IUniswapV3Pool.sol";

contract OracleLibraryTest is Test {
    /**
    IUniswapV3Pool pool;
    address poolAddress = address(0x1234567890abcdef1234567890abcdef12345678);

    function setUp() public {
        pool = IUniswapV3Pool(poolAddress);
    }

    function testConsult() public {
        // Mock the pool's observe function
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.observe.selector),
            abi.encode(
                new int56[](2),
                new uint160[](2)
            )
        );

        (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity) = OracleLibrary.consult(poolAddress, 60);
        assertEq(arithmeticMeanTick, 0);
        assertEq(harmonicMeanLiquidity, 0);
    }

    function testGetQuoteAtTick() public {
        int24 tick = 100;
        uint128 baseAmount = 1000;
        address baseToken = address(0x1);
        address quoteToken = address(0x2);

        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(tick, baseAmount, baseToken, quoteToken);
        assertGt(quoteAmount, 0);
    }

    function testGetOldestObservationSecondsAgo() public {
        // Mock the pool's slot0 and observations functions
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.slot0.selector),
            abi.encode(0, 0, 0, 2, 0, 0, 0)
        );
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.observations.selector),
            abi.encode(0, 0, 0, true)
        );

        uint32 secondsAgo = OracleLibrary.getOldestObservationSecondsAgo(poolAddress);
        assertEq(secondsAgo, 0);
    }

    function testGetBlockStartingTickAndLiquidity() public {
        // Mock the pool's slot0 and observations functions
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.slot0.selector),
            abi.encode(0, 100, 0, 2, 0, 0, 0)
        );
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.observations.selector),
            abi.encode(uint32(block.timestamp), 0, 0, true)
        );

        (int24 tick, uint128 liquidity) = OracleLibrary.getBlockStartingTickAndLiquidity(poolAddress);
        assertEq(tick, 100);
        assertEq(liquidity, 0);
    }

    function testGetWeightedArithmeticMeanTick() public {
        OracleLibrary.WeightedTickData[] memory data = new OracleLibrary.WeightedTickData[](2);
        data[0] = OracleLibrary.WeightedTickData({tick: 100, weight: 1});
        data[1] = OracleLibrary.WeightedTickData({tick: 200, weight: 2});

        int24 weightedTick = OracleLibrary.getWeightedArithmeticMeanTick(data);
        assertEq(weightedTick, 166);
    }

    function testGetChainedPrice() public {
        address[] memory tokens = new address[](3);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);
        tokens[2] = address(0x3);

        int24[] memory ticks = new int24[](2);
        ticks[0] = 100;
        ticks[1] = 200;

        int256 syntheticTick = OracleLibrary.getChainedPrice(tokens, ticks);
        assertEq(syntheticTick, 300);
    }

    function testGetLatestTick() public {
        // Mock the pool's slot0 function
        vm.mockCall(
            poolAddress,
            abi.encodeWithSelector(IUniswapV3Pool.slot0.selector),
            abi.encode(0, 100, 0, 0, 0, 0, 0)
        );

        int24 tick = OracleLibrary.getLatestTick(poolAddress);
        assertEq(tick, 100);
    }
    */
}
