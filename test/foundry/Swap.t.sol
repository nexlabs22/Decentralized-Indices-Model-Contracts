// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/token/IndexToken.sol";
import "../../contracts/Swap.sol";
import "../../contracts/test/MockV3Aggregator.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";
import "../../contracts/interfaces/IWETH.sol";
import "../../contracts/interfaces/IUniswapV3Factory2.sol";
import "../../contracts/interfaces/IUniswapV2Router02.sol";
import "../../contracts/uniswap/ISwapRouter.sol";
import "../../contracts/uniswap/INonfungiblePositionManager.sol";
import "../../contracts/uniswap/Token.sol";
import "./ContractDeployer.sol";

contract CounterTest is Test, ContractDeployer {


    uint256 internal constant SCALAR = 1e20;

    


    event FeeReceiverSet(address indexed feeReceiver);
    event FeeRateSet(uint256 indexed feeRatePerDayScaled);
    event MethodologistSet(address indexed methodologist);
    event MethodologySet(string methodology);
    event MinterSet(address indexed minter);
    event SupplyCeilingSet(uint256 supplyCeiling);
    event MintFeeToReceiver(address feeReceiver, uint256 timestamp, uint256 totalSupply, uint256 amount);
    event ToggledRestricted(address indexed account, bool isRestricted);

    
    function setUp() public {
        deployAllContracts();
        
        indexToken.setMinter(minter);
        
    }

    function testInitialized() public {
        assertEq(IUniswapV3Factory2(factoryAddress).owner(), address(this));
        
        assertEq(IUniswapV2Router02(router).factory(), factoryAddress);
        
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000e18);
        assertEq(indexToken.minter(), minter);
    }

    

    function testAddLiquidity() public {
        
        addLiquidity(positionManager, factoryAddress, token0, token1, 1000e18, 1000e18);
        address poolAddress = IUniswapV3Factory2(factoryAddress).getPool(address(token0), address(token1), 3000);
        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", token1.balanceOf(poolAddress));
        token0.approve(router, 100e18);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams(
            address(token0),
            address(token1),
            3000,
            address(this),
            block.timestamp,
            100e18,
            0,
            0
        );
        ISwapRouter(router).exactInputSingle(swapParams);

        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", token1.balanceOf(poolAddress));

    }

    function testAddLiquidityETH() public {
        
        addLiquidityETH(positionManager, factoryAddress, token0, wethAddress, 1000e18, 1e18);
        address poolAddress = IUniswapV3Factory2(factoryAddress).getPool(address(token0), address(weth), 3000);
        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", Token(wethAddress).balanceOf(poolAddress));
        token0.approve(router, 100e18);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams(
            address(token0),
            address(wethAddress),
            3000,
            address(this),
            block.timestamp,
            100e18,
            0,
            0
        );
        ISwapRouter(router).exactInputSingle(swapParams);

        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", Token(wethAddress).balanceOf(poolAddress));

    }

    

    
}