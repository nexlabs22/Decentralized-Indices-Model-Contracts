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
import "../../contracts/factory/IPriceOracle.sol";

import "./ContractDeployer.sol";

contract TestSwap is Test, ContractDeployer {

    using stdStorage for StdStorage;

    uint256 internal constant SCALAR = 1e20;

    
    uint256 mainnetFork;

    

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    

    
    receive() external payable {}

    function setUp() public {
        
        deployAllContracts(1000000e18);
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token1, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token2, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token3, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, token4, wethAddress, 1000e18, 1e18);
        addLiquidityETH(positionManager, factoryAddress, usdt, wethAddress, 1000e18, 1e18);

        addLiquidity(positionManager, factoryAddress, token0, token1, 1000e18, 1000e18);
        
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


    
    function testSwapSingle() public {
        token0.transfer(address(minter), 1e18);

        console.log(token0.balanceOf(address(minter)));
        vm.startPrank(minter);
        //estimate amount out
        uint amountIn = 1e18;
        uint estAmountOut = estimateAmountOut(address(token0), address(weth), amountIn, 3000);
        token0.transfer(address(minter), 1e18);

        token0.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(token0),
            tokenOut: address(weth),
            fee: 3000,
            recipient: address(minter),
            deadline: block.timestamp + 300,
            amountIn:  amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uint amountOut = swapRouter.exactInputSingle(params);
        console.log(token0.balanceOf(address(minter)));
        console.log(amountOut);
        console.log(estAmountOut);
    }

    function estimateAmountOut(
        address token0,
        address token1,
        uint amountIn,
        uint24 fee
    ) public view returns(uint) {
        return IPriceOracle(priceOracleAddress).estimateAmountOut(
            address(factoryAddress),
            token0,
            token1,
            uint128(amountIn),
            fee
        );
    }


    function testSwapMultiple() public {
        address[] memory path = new address[](3);
        path[0] = address(token0);
        path[1] = address(token1);
        path[2] = address(weth);

        // bytes memory pathBytes = abi.encode(path);
        bytes memory pathBytes = abi.encodePacked(
            address(token0),   // Address of TokenA
            uint24(3000), // Fee tier between TokenA and TokenB
            address(token1),   // Address of TokenA
            uint24(3000), // Fee tier between TokenA and TokenB
            address(weth)    // Address of TokenB
        );
        //estimate amount out
        uint amountIn = 1e18;
        uint estAmountOut;
        uint lastAmount = amountIn;
        for(uint i = 0; i < path.length - 1; i++) {
            lastAmount = estimateAmountOut(path[i], path[i+1], lastAmount, 3000);
        }
        estAmountOut = lastAmount;
        // uint estAmountOut = estimateAmountOut(address(token0), address(weth), amountIn, 3000);
        token0.transfer(address(minter), 1e18);

        console.log(token0.balanceOf(address(minter)));
        vm.startPrank(minter);
        token0.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: pathBytes,
            recipient: address(minter),
            deadline: block.timestamp + 300,
            amountIn:  amountIn,
            amountOutMinimum: 0
        });
        uint amountOut = swapRouter.exactInput(params);

        console.log(token0.balanceOf(address(minter)));
        console.log(amountOut);
        console.log(estAmountOut);
    }
    
    
    

    
}