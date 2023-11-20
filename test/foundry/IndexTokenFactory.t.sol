// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/token/IndexToken.sol";
import "../../contracts/test/TestSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../../contracts/test/MockV3Aggregator.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";

contract CounterTest is Test {


    uint256 internal constant SCALAR = 1e20;

    IndexToken public indexToken;
    TestSwap public testSwap;

    uint256 mainnetFork;

    address feeReceiver = vm.addr(1);
    address newFeeReceiver = vm.addr(2);
    address minter = vm.addr(3);
    address newMinter = vm.addr(4);
    address methodologist = vm.addr(5);
    address add1 = vm.addr(6);

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    address public SHIB = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public constant PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    address public constant FLOKI = 0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E;
    address public constant MEME = 0xb131f4A55907B10d1F0A50d8ab8FA09EC342cd74;
    address public constant BabyDoge = 0xAC57De9C1A09FeC648E93EB98875B212DB0d460B;
    address public constant BONE = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
    address public constant HarryPotterObamaSonic10Inu = 0x72e4f9F808C49A2a61dE9C5896298920Dc4EEEa9;
    address public constant ELON = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
    address public constant WSM = 0xB62E45c3Df611dcE236A6Ddc7A493d79F9DFadEf;
    address public constant LEASH = 0x27C70Cd1946795B66be9d954418546998b546634;

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    ERC20 public dai;
    IWETH public weth;

    // Swap public swap;
    IQuoter public quoter;

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    bytes32 jobId = "6b88e0402e5d415eb946e528b8e0c7ba";

    MockApiOracle public oracle;
    LinkToken link;

    event FeeReceiverSet(address indexed feeReceiver);
    event FeeRateSet(uint256 indexed feeRatePerDayScaled);
    event MethodologistSet(address indexed methodologist);
    event MethodologySet(string methodology);
    event MinterSet(address indexed minter);
    event SupplyCeilingSet(uint256 supplyCeiling);
    event MintFeeToReceiver(address feeReceiver, uint256 timestamp, uint256 totalSupply, uint256 amount);
    event ToggledRestricted(address indexed account, bool isRestricted);


    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        LinkToken link = new LinkToken();
        oracle = new MockApiOracle(address(link));

        indexToken = new IndexToken();
        indexToken.initialize(
            "Anti Inflation",
            "ANFI",
            1e18,
            feeReceiver,
            1000000e18,
            address(oracle),
            jobId,
            1e17,
            address(link)
        );
        indexToken.setMinter(minter);

        // swap = new Swap();
        dai = ERC20(DAI);
        weth = IWETH(WETH9);
        quoter = IQuoter(QUOTER);

        testSwap = new TestSwap();

        
    }

    function testInitialized() public {
        // counter.increment();
        assertEq(indexToken.owner(), address(this));
        assertEq(indexToken.feeRatePerDayScaled(), 1e18);
        assertEq(indexToken.feeTimestamp(), block.timestamp);
        assertEq(indexToken.feeReceiver(), feeReceiver);
        assertEq(indexToken.methodology(), "");
        assertEq(indexToken.supplyCeiling(), 1000000e18);
        assertEq(indexToken.minter(), minter);
    }

    enum DexStatus {
        UNISWAP_V2,
        UNISWAP_V3
    }

    function testMintWithSwap() public {
        uint startAmount = 1e14;
        vm.selectFork(mainnetFork);

        console.log("shib", IERC20(SHIB).balanceOf(address(indexToken)));
        console.log("expect", indexToken.estimateAmountOut(WETH9, SHIB, 10e18, 1));
        indexToken.swapGas{value: 10e18}();
        console.log("shib", IERC20(SHIB).balanceOf(address(indexToken)));
        indexToken.swapGas1{value: 10e18}();
        console.log("shib", IERC20(SHIB).balanceOf(address(indexToken)));
        // weth.deposit{value: startAmount}();
        // assertEq(weth.balanceOf(address(this)), startAmount);
        // weth.approve(address(swapRouter), startAmount);
        
        // ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        // .ExactInputSingleParams({
        //     tokenIn: WETH9,
        //     tokenOut: DAI,
        //     // pool fee 0.3%
        //     fee: 3000,
        //     recipient: address(this),
        //     deadline: block.timestamp,
        //     amountIn: startAmount,
        //     amountOutMinimum: 0,
        //     // NOTE: In production, this value can be used to set the limit
        //     // for the price the swap will push the pool to,
        //     // which can help protect against price impact
        //     sqrtPriceLimitX96: 0
        // });

        // uint daiAmount = swapRouter.exactInputSingle(params);
        // console.log(daiAmount);
        // console.log(dai.balanceOf(address(this)));
        // console.log(weth.balanceOf(address(testSwap)));


        // dai.approve(address(indexToken), dai.balanceOf(address(this)));
        // indexToken.issuanceIndexTokens(DAI, dai.balanceOf(address(this)));
        ////
        // indexToken.issuanceIndexTokensWithEth{value: 1e18}();
        
        // console.log(weth.balanceOf(address(this)));
        // console.log(indexToken.balanceOf(address(this)));
        // console.log(indexToken.getPortfolioBalance());
        // indexToken.redemption(WETH9, indexToken.balanceOf(address(this)));
        // console.log(weth.balanceOf(address(this)));
        // console.log(indexToken.balanceOf(address(this)));
        // console.log(indexToken.getPortfolioBalance());

        // dai.approve(address(testSwap), dai.balanceOf(address(this)));
        // testSwap.deposit(dai.balanceOf(address(this)));

        // console.log(dai.balanceOf(address(this)));
        // console.log(weth.balanceOf(address(testSwap)));

    }


    function testTSwap() public {
        // testSwap.deposit{value: 1e16}();
    }

    

    
}