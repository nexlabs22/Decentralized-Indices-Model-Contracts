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

    IndexToken public indexToken;
    Swap public swap;
    // bytes32 jobId = "6b88e0402e5d415eb946e528b8e0c7ba";

    MockApiOracle public oracle;
    LinkToken link;

    // address feeReceiver = vm.addr(1);
    // address newFeeReceiver = vm.addr(2);
    // address minter = vm.addr(3);
    // address newMinter = vm.addr(4);
    // address methodologist = vm.addr(5);


    event FeeReceiverSet(address indexed feeReceiver);
    event FeeRateSet(uint256 indexed feeRatePerDayScaled);
    event MethodologistSet(address indexed methodologist);
    event MethodologySet(string methodology);
    event MinterSet(address indexed minter);
    event SupplyCeilingSet(uint256 supplyCeiling);
    event MintFeeToReceiver(address feeReceiver, uint256 timestamp, uint256 totalSupply, uint256 amount);
    event ToggledRestricted(address indexed account, bool isRestricted);

    // address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    // address public constant SwapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // address public constant FactoryV3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // address public constant SwapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address public constant FactoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    Token token0;
    Token token1;
    address factory;
    address weth;
    address router;
    address positionManager;
    function setUp() public {
        (link, oracle, indexToken,,,) = deployContracts();
        (token0, token1) = deployTokens();
        indexToken.setMinter(minter);
        (factory, weth, router, positionManager) = deployUniswap();
        // console.log("factory address", factory);
        // console.log("factory owner", IUniswapV3Factory2(factory).owner());
        // console.log("this address", address(this));
        // IWETH(weth).deposit{value:1}();
        // console.log("weth balancer", IWETH(weth).balanceOf(address(this)));
        // console.log("router's factory address", IUniswapV2Router02(router).factory());
        // console.log("position manager", positionManager);
        /**
        indexToken = new IndexToken();
        indexToken.initialize(
            "Anti Inflation",
            "ANFI",
            1e18,
            feeReceiver,
            1000000e18,
            //swap addresses
            WETH9,
            QUOTER,
            SwapRouterV3,
            FactoryV3,
            SwapRouterV2,
            FactoryV2
        );
        indexToken.setMinter(minter);

        //swap
        swap = new Swap();
         */
    }

    function testInitialized() public {
        assertEq(IUniswapV3Factory2(factory).owner(), address(this));
        
        assertEq(IUniswapV2Router02(router).factory(), factory);
        
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000e18);
        assertEq(indexToken.minter(), minter);
    }

    

    function testAddLiquidity() public {
        
        addLiquidity(positionManager, factory, token0, token1, 1000e18, 1000e18);
        address poolAddress = IUniswapV3Factory2(factory).getPool(address(token0), address(token1), 3000);
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
        
        addLiquidityETH(positionManager, factory, token0, weth, 1000e18, 1e18);
        address poolAddress = IUniswapV3Factory2(factory).getPool(address(token0), address(weth), 3000);
        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", Token(weth).balanceOf(poolAddress));
        token0.approve(router, 100e18);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams(
            address(token0),
            address(weth),
            3000,
            address(this),
            block.timestamp,
            100e18,
            0,
            0
        );
        ISwapRouter(router).exactInputSingle(swapParams);

        console.log("token0 balance:", token0.balanceOf(poolAddress));
        console.log("token1 balance:", Token(weth).balanceOf(poolAddress));

    }

    

    
}