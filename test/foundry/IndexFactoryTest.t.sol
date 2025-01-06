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
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../../contracts/token/IndexToken.sol";

contract IndexFactoryTest is Test, IndexFactory {
    IndexFactory indexFactory;
    ContractDeployer deployer;
    // MockFactoryStorage Fstorage;
    IndexFactoryStorage Fstorage;
    IWETH weth;
    LinkToken link;
    MockApiOracle oracle;
    Vault vault;
    ISwapRouter swapRouter;
    IndexToken indexToken;
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
        swapRouter = deployer.swapRouter();
        indexToken = deployer.indexToken();

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

    function test_Issuance_MutationKiller() public {
        console.log("Starting test_Issuance_MutationKiller...");

        address user = address(0x1111);
        vm.deal(user, 10 ether);
        vm.startPrank(user);

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(2))
        );

        address someToken = address(0xAAA1);
        address wethAddr = address(Fstorage.weth());
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 0), abi.encode(someToken));
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 1), abi.encode(wethAddr));

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenCurrentMarketShare.selector, someToken),
            abi.encode(uint256(50e18))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenCurrentMarketShare.selector, wethAddr),
            abi.encode(uint256(50e18))
        );

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, someToken),
            abi.encode(uint24(3000))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, wethAddr),
            abi.encode(uint24(3000))
        );

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector),
            abi.encode(uint256(1000e18))
        );

        address tokenIn = someToken;
        uint256 amountIn = 3e18;

        vm.mockCall(
            tokenIn,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector, user, address(indexFactory), amountIn + (amountIn / 100)
            ),
            abi.encode(true)
        );
        vm.mockCall(address(indexFactory), bytes(""), abi.encode(uint256(303e16)));

        address feeReceiver = Fstorage.feeReceiver();
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, uint256(303e14)), abi.encode(true)
        );

        vm.mockCall(address(indexFactory), bytes(""), abi.encode(uint256(150e16)));
        vm.mockCall(wethAddr, bytes(""), abi.encode(true));

        console.log("Calling issuanceIndexTokens(...), should not revert if all mocked");
        indexFactory.issuanceIndexTokens(tokenIn, amountIn, 3000);

        console.log("test_Issuance_MutationKiller completed without revert.");
        vm.stopPrank();
    }

    function test_RedemptionSwaps_MutationKiller() public {
        console.log("Starting test_RedemptionSwaps_MutationKiller...");

        address user = address(0x2222);
        vm.deal(user, 10 ether);
        vm.startPrank(user);

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(2))
        );
        address tokenNonWeth = address(0x3333);
        address wethAddr = address(Fstorage.weth());
        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 0), abi.encode(tokenNonWeth)
        );
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 1), abi.encode(wethAddr));

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, tokenNonWeth),
            abi.encode(uint24(3000))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, wethAddr),
            abi.encode(uint24(3000))
        );

        address vaultAddr = address(Fstorage.vault());
        vm.mockCall(
            tokenNonWeth, abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr), abi.encode(uint256(500e18))
        );
        vm.mockCall(wethAddr, abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr), abi.encode(uint256(800e18)));

        vm.mockCall(vaultAddr, bytes(""), abi.encode(true));

        vm.mockCall(address(indexFactory), bytes(""), abi.encode(uint256(123e16)));

        vm.mockCall(wethAddr, bytes(""), abi.encode(true));

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(100)));
        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.feeReceiver.selector), abi.encode(address(0xFEE1))
        );
        vm.mockCall(
            address(Fstorage.indexToken()),
            abi.encodeWithSelector(ERC20Upgradeable.totalSupply.selector),
            abi.encode(uint256(10e18))
        );

        vm.mockCall(
            address(Fstorage.indexToken()), abi.encodeWithSignature("burn(address,uint256)", user, 2e18), bytes("")
        );

        console.log("Calling redemption(2e18, WETH, 3000)...");
        indexFactory.redemption(2e18, wethAddr, 3000);
        console.log("test_RedemptionSwaps_MutationKiller completed without revert.");
        vm.stopPrank();
    }

    function testRedemption_BurnPercentMutations() public {
        address user = address(0xBABE);
        deal(user, 10 ether);

        address tokenNonWeth = address(0x1111);
        address wethAddr = address(Fstorage.weth());

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(2))
        );
        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 0), abi.encode(tokenNonWeth)
        );
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 1), abi.encode(wethAddr));

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(100)));

        vm.mockCall(
            address(Fstorage.indexToken()),
            abi.encodeWithSelector(ERC20Upgradeable.totalSupply.selector),
            abi.encode(uint256(10e18))
        );

        uint256 amountIn = 2e18;
        vm.mockCall(
            address(Fstorage.indexToken()), abi.encodeWithSignature("burn(address,uint256)", user, amountIn), bytes("")
        );

        address vaultAddr = address(Fstorage.vault());

        vm.mockCall(
            tokenNonWeth, abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr), abi.encode(uint256(1000e18))
        );
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr), abi.encode(uint256(1000e18))
        );

        vm.mockCall(vaultAddr, bytes(""), abi.encode(true));

        vm.mockCall(address(indexFactory), bytes(""), abi.encode(uint256(50)));
        vm.mockCall(wethAddr, bytes(""), abi.encode(true));

        vm.startPrank(user);
        indexFactory.redemption(amountIn, wethAddr, 3000);
        vm.stopPrank();
    }

    function testRedemption_NoRevert() public {
        address user = address(0xBABE);
        deal(user, 10 ether);
        address tokenNonWeth = address(0x1111);
        address wethAddr = address(Fstorage.weth());

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(2))
        );
        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 0), abi.encode(tokenNonWeth)
        );
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 1), abi.encode(wethAddr));

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, tokenNonWeth),
            abi.encode(uint24(3000))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, wethAddr),
            abi.encode(uint24(3000))
        );

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(100)));
        address feeReceiver = address(0xFEE1);
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeReceiver.selector), abi.encode(feeReceiver));

        vm.mockCall(
            address(Fstorage.indexToken()),
            abi.encodeWithSelector(ERC20Upgradeable.totalSupply.selector),
            abi.encode(uint256(10e18))
        );

        vm.mockCall(
            address(Fstorage.indexToken()), abi.encodeWithSignature("burn(address,uint256)", user, 2e18), bytes("")
        );

        address vaultAddr = address(Fstorage.vault());

        vm.mockCall(
            address(tokenNonWeth),
            abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr),
            abi.encode(uint256(1000e18))
        );

        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.balanceOf.selector, vaultAddr), abi.encode(uint256(1000e18))
        );

        vm.mockCall(vaultAddr, bytes(""), abi.encode(true));

        vm.mockCall(address(indexFactory), bytes(""), abi.encode(uint256(123)));

        vm.mockCall(wethAddr, bytes(""), abi.encode(true));

        vm.startPrank(user);
        indexFactory.redemption(2e18, wethAddr, 3000);

        vm.stopPrank();
    }

    function testIssuanceIndexTokensWithEth_FeeAndReentrancyMutations_SmallAmount() public {
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(100)));

        uint256 inputAmount = 3e18;
        address user = address(0x999);

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector), abi.encode(uint256(1e21))
        );

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(0))
        );

        address vaultAddr = address(Fstorage.vault());
        IWETH weth = Fstorage.weth();
        address wethAddr = address(weth);

        address feeReceiver = Fstorage.feeReceiver();

        vm.deal(user, 5 ether);
        vm.startPrank(user);

        uint256 finalAmount = inputAmount + ((inputAmount * 100) / 10000);

        vm.mockCall(wethAddr, abi.encodeWithSelector(IWETH.deposit.selector), bytes(""));

        uint256 feeAmount = (inputAmount * 100) / 10000;
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, feeAmount), abi.encode(true)
        );

        indexFactory.issuanceIndexTokensWithEth{value: finalAmount}(inputAmount);

        vm.expectRevert();
        indexFactory.issuanceIndexTokensWithEth{value: finalAmount}(inputAmount);

        vm.stopPrank();
    }

    function testIssuanceIndexTokens_FeeAndReentrancyMutations_SmallAmount() public {
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(100)));

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(0))
        );

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector), abi.encode(uint256(1e21))
        );

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.priceInWei.selector), abi.encode(uint256(2e18)));

        address user = address(0x2);
        address tokenIn = address(0x1234);
        uint256 amountIn = 5e18;
        uint256 feeRate = 100;
        uint256 feeAmount = (amountIn * feeRate) / 10000;
        uint256 totalTransfer = amountIn + feeAmount;

        vm.mockCall(
            tokenIn,
            abi.encodeWithSelector(IERC20.transferFrom.selector, user, address(indexFactory), totalTransfer),
            abi.encode(true)
        );

        address router = address(Fstorage.swapRouterV3());
        address routerV2 = address(Fstorage.swapRouterV2());
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.swapRouterV3.selector), abi.encode(router));
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.swapRouterV2.selector), abi.encode(routerV2));

        vm.mockCall(tokenIn, abi.encodeWithSelector(IERC20.approve.selector, router, totalTransfer), abi.encode(true));

        vm.mockCall(router, bytes(""), abi.encode(uint256(totalTransfer)));

        address wethAddr = address(Fstorage.weth());
        address feeReceiver = Fstorage.feeReceiver();
        uint256 feeWethAmount = (totalTransfer * feeRate) / 10000;
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, feeWethAmount), abi.encode(true)
        );

        vm.startPrank(user);
        indexFactory.issuanceIndexTokens(tokenIn, amountIn, 3000);
        vm.stopPrank();

        vm.expectRevert();
        indexFactory.issuanceIndexTokens(tokenIn, amountIn, 3000);
    }

    function testIssuance_TriggerAllMutations() public {
        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.totalCurrentList.selector), abi.encode(uint256(2))
        );

        address token1Addr = address(0x1111);
        address wethAddr = address(Fstorage.weth());

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 0), abi.encode(token1Addr));
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.currentList.selector, 1), abi.encode(wethAddr));

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenCurrentMarketShare.selector, token1Addr),
            abi.encode(uint256(50e18))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenCurrentMarketShare.selector, wethAddr),
            abi.encode(uint256(50e18))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, token1Addr),
            abi.encode(uint24(3000))
        );
        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.tokenSwapFee.selector, wethAddr),
            abi.encode(uint24(3000))
        );

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector),
            abi.encode(uint256(1000e18))
        );
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(0)));

        address user = address(0xABC);
        deal(user, 10 ether);
        vm.startPrank(user);

        vm.mockCall(
            wethAddr,
            abi.encodeWithSelector(IERC20.transferFrom.selector, user, address(indexFactory), 10e18),
            abi.encode(true)
        );

        address swapRouterV3Addr = address(Fstorage.swapRouterV3());
        vm.mockCall(swapRouterV3Addr, bytes(""), abi.encode(uint256(123)));

        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.approve.selector, swapRouterV3Addr, 10e18), abi.encode(true)
        );

        address feeReceiver = Fstorage.feeReceiver();
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, uint256(0)), abi.encode(true)
        );

        address vaultAddr = address(Fstorage.vault());
        vm.mockCall(
            wethAddr, abi.encodeWithSelector(IERC20.transfer.selector, vaultAddr, uint256(61)), abi.encode(true)
        );

        indexFactory.issuanceIndexTokens(wethAddr, 10e18, 3000);

        vm.stopPrank();
    }

    function testIssuanceIndexTokens_TotalSupplyScenarios() public {
        vm.mockCall(
            address(Fstorage.indexToken()),
            abi.encodeWithSelector(ERC20Upgradeable.totalSupply.selector),
            abi.encode(uint256(0))
        );

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.priceInWei.selector), abi.encode(uint256(2_000_000))
        );

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector),
            abi.encode(uint256(999e18))
        );
        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(0)));

        address userA = address(0xAAA);
        deal(userA, 10 ether);
        vm.startPrank(userA);

        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IERC20.transferFrom.selector, userA, address(indexFactory), 10e18),
            abi.encode(true)
        );

        ISwapRouter.ExactInputSingleParams memory paramsZeroTS = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(weth),
            fee: 3000,
            recipient: address(indexFactory),
            deadline: 301,
            amountIn: 10e18,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        vm.mockCall(
            address(Fstorage.swapRouterV3()),
            abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, paramsZeroTS),
            abi.encode(uint256(10e18))
        );

        address feeReceiver = Fstorage.feeReceiver();
        vm.mockCall(
            address(weth), abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, uint256(0)), abi.encode(true)
        );

        indexFactory.issuanceIndexTokens(address(weth), 10e18, 3000);

        uint256 userAMinted = Fstorage.indexToken().balanceOf(userA);
        uint256 expectedA = 2_000_000_000;
        assertEq(userAMinted, expectedA, "Mint mismatch in totalSupply=0 scenario");

        vm.stopPrank();

        vm.mockCall(
            address(Fstorage.indexToken()),
            abi.encodeWithSelector(ERC20Upgradeable.totalSupply.selector),
            abi.encode(uint256(1000e18))
        );

        vm.mockCall(
            address(Fstorage),
            abi.encodeWithSelector(Fstorage.getPortfolioBalance.selector),
            abi.encode(uint256(500e18))
        );

        vm.mockCall(
            address(Fstorage), abi.encodeWithSelector(Fstorage.priceInWei.selector), abi.encode(uint256(999999))
        );

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.feeRate.selector), abi.encode(uint256(0)));

        address userB = address(0xBBB);
        deal(userB, 10 ether);
        vm.startPrank(userB);

        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IERC20.transferFrom.selector, userB, address(indexFactory), 10e18),
            abi.encode(true)
        );

        ISwapRouter.ExactInputSingleParams memory paramsNonZeroTS = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(weth),
            fee: 3000,
            recipient: address(indexFactory),
            deadline: 301,
            amountIn: 10e18,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        vm.mockCall(
            address(Fstorage.swapRouterV3()),
            abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, paramsNonZeroTS),
            abi.encode(uint256(10e18))
        );

        vm.mockCall(
            address(weth), abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, uint256(0)), abi.encode(true)
        );

        indexFactory.issuanceIndexTokens(address(weth), 10e18, 3000);

        uint256 userBMinted = Fstorage.indexToken().balanceOf(userB);
        uint256 expectedB = 20e18;
        assertEq(userBMinted, expectedB, "Mint mismatch in totalSupply>0 scenario");

        vm.stopPrank();
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

    function testExponentiation_CorrectScaling() public {
        uint8 amountDecimals = 3;
        uint8 chainDecimals = 6;

        uint256 expected = 10 ** (chainDecimals - amountDecimals);
        uint256 mutated = 10 * (chainDecimals - amountDecimals);

        assertEq(expected, 1000, "Incorrect exponentiation");
        assertFalse(expected == mutated, "Mutation not detected");
    }

    function testTotalSupplyComparison() public {
        uint256 totalSupply = 1000;

        bool original = totalSupply > 0;
        bool mutated = totalSupply < 0;

        assertTrue(original, "Original condition failed");
        assertFalse(original == mutated, "Mutation not detected");
    }

    function test_toWei_Mutations2() public {
        int256 amount = 100;
        uint8 amountDecimals = 8;
        uint8 chainDecimals = 18;

        int256 expected = amount * int256(10 ** (chainDecimals - amountDecimals));

        int256 actual = _toWei(amount, amountDecimals, chainDecimals);

        {
            int256 mutatedDivision = amount / int256(10 ** (chainDecimals - amountDecimals));
            assertFalse(mutatedDivision == actual, "Mutation not killed: changed multiply to division");
        }

        {
            uint256 mutatedMultiplier = 10 * (chainDecimals - amountDecimals);
            int256 mutatedResult = amount * int256(mutatedMultiplier);
            assertFalse(mutatedResult == actual, "Mutation not killed: replaced exponent with a simple multiply");
        }

        {
            int256 mutatedExponent = int256(10 ** uint256(chainDecimals + amountDecimals));
            int256 mutatedResult = amount * mutatedExponent;
            assertFalse(mutatedResult == actual, "Mutation not killed: replaced '-' with '+' in exponent calculation");
        }

        assertEq(actual, expected, "Original _toWei logic is incorrect for this input");
    }

    function testIssuanceIndexTokens_FeeCalculation() public {
        address user = address(0x1111);
        uint256 amountIn = 1 ether;
        uint256 feeRate = 100;
        uint256 feeAmount = (amountIn * feeRate) / 10000;

        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.weth.selector), abi.encode(address(weth))
        );
        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.feeRate.selector), abi.encode(feeRate)
        );
        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.feeReceiver.selector),
            abi.encode(address(0xFEE1))
        );

        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.totalCurrentList.selector),
            abi.encode(uint256(1))
        );

        uint256 wethAmountBeforeFee = 10 ether;
        uint256 mutatedWethAmount = wethAmountBeforeFee + feeAmount;

        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IERC20.transfer.selector, address(0xFEE1), feeAmount),
            abi.encode(true)
        );

        vm.startPrank(user);
        vm.expectRevert();
        indexFactory.issuanceIndexTokens(address(weth), amountIn, 3000);
        vm.stopPrank();
    }

    function testIssuanceIndexTokens_ReentrancyProtection() public {
        address attacker = address(this);
        uint256 amountIn = 1 ether;

        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.weth.selector), abi.encode(address(weth))
        );
        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.vault.selector), abi.encode(address(vault))
        );
        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.totalCurrentList.selector),
            abi.encode(uint256(1))
        );
        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.feeRate.selector), abi.encode(uint256(100))
        );

        vm.startPrank(attacker);
        vm.expectRevert();
        indexFactory.issuanceIndexTokens(address(weth), amountIn, 3000);
        vm.stopPrank();
    }

    function testIssuanceIndexTokensWithEth_FeeCalculation() public {
        uint256 inputAmount = 1 ether;
        uint256 feeRate = 100;
        uint256 feeAmount = (inputAmount * feeRate) / 10000;

        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.feeRate.selector), abi.encode(feeRate)
        );
        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.feeReceiver.selector),
            abi.encode(address(0xFEE1))
        );
        vm.mockCall(
            address(factoryStorage), abi.encodeWithSelector(factoryStorage.vault.selector), abi.encode(address(vault))
        );

        uint256 mutatedFinalAmount = inputAmount - feeAmount;

        vm.startPrank(address(this));
        vm.expectRevert("lower than required amount");
        indexFactory.issuanceIndexTokensWithEth{value: mutatedFinalAmount}(inputAmount);
        vm.stopPrank();
    }

    function testSwapToOutputToken_Mutations() public {
        uint256 amountIn = 10 ether;
        uint256 outputAmount = 5 ether;
        uint24 tokenOutSwapFee = 3000;
        uint256 feeRate = 100;
        address feeReceiver = address(0xFEE1);
        address tokenOut = address(0x1111);
        address wethAddress = address(Fstorage.weth());

        vm.mockCall(address(Fstorage), abi.encodeWithSelector(Fstorage.weth.selector), abi.encode(wethAddress));
        vm.mockCall(
            wethAddress,
            abi.encodeWithSelector(IERC20.transfer.selector, feeReceiver, (outputAmount * feeRate) / 10000),
            abi.encode(true)
        );
        vm.mockCall(
            wethAddress,
            abi.encodeWithSelector(IWETH.withdraw.selector, outputAmount - ((outputAmount * feeRate) / 10000)),
            abi.encode()
        );

        address uniswapRouter = address(swapRouter);
        vm.mockCall(
            uniswapRouter,
            abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector),
            abi.encode(outputAmount - ((outputAmount * feeRate) / 10000))
        );

        vm.startPrank(address(this));
        vm.expectRevert();
        uint256 mutatedOwnerFee = (outputAmount * feeRate) * 10000;
        _swapToOutputToken(amountIn, outputAmount, tokenOut, tokenOutSwapFee, mutatedOwnerFee, feeReceiver);

        vm.expectRevert();
        uint256 divisionFee = outputAmount / feeRate;
        _swapToOutputToken(amountIn, outputAmount, tokenOut, tokenOutSwapFee, divisionFee, feeReceiver);

        tokenOut = wethAddress;
        vm.expectRevert();
        bool mutatedCondition = tokenOut != wethAddress;
        _swapToOutputToken(
            amountIn, outputAmount, mutatedCondition ? address(0) : tokenOut, tokenOutSwapFee, feeRate, feeReceiver
        );

        uint256 mutatedOutputAmount = outputAmount + ((outputAmount * feeRate) / 10000);
        vm.expectRevert();
        _swapToOutputToken(amountIn, mutatedOutputAmount, tokenOut, tokenOutSwapFee, feeRate, feeReceiver);

        vm.stopPrank();
    }
}
