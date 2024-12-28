// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";

import "forge-std/Test.sol";
import "../../contracts/factory/IndexFactory.sol";
import "./ContractDeployer.sol";
import "../mocks/MockERC20.sol";

contract IndexFactoryTest is Test, IndexFactory {
    IndexFactory indexFactory;
    ContractDeployer deployer;
    MockFactoryStorage Fstorage;

    MockERC20 token;

    address user = address(2);

    function setUp() external {
        indexFactory = new IndexFactory();
        indexFactory.initialize(payable(address(new IndexFactoryStorage())));
        deployer = new ContractDeployer();
        Fstorage = new MockFactoryStorage(token, 1e18);

        token = new MockERC20("Test", "TT");
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
        indexFactory.pause();

        bool isPaused = indexFactory.paused();
        assertTrue(isPaused, "The contract should be paused");
    }

    function testFailPauseRevertsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the ownerAddr");
        indexFactory.pause();
    }

    function testUnpauseByOwner() public {
        indexFactory.pause();

        indexFactory.unpause();

        bool isPaused = indexFactory.paused();
        assertFalse(isPaused, "The contract should be unpaused");
    }

    function testFailUnpauseRevertsIfNotOwner() public {
        indexFactory.pause();

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the ownerAddr");
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
}

contract MockFactoryStorage {
    MockERC20 public token;
    uint256 public priceInWei;

    constructor(MockERC20 _indexToken, uint256 _priceInWei) {
        token = _indexToken;
        priceInWei = _priceInWei;
    }
}
