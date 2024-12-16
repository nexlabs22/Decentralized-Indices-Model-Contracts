// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../../contracts/interfaces/IUniswapV2Router02.sol";
import "../../contracts/factory/IndexFactoryBalancer.sol";
import "../../contracts/factory/IndexFactoryStorage.sol";
import "../../contracts/libraries/SwapHelpers.sol";

contract IndexFactoryBalancerTest is Test {
    IndexFactoryBalancer indexFactoryBalancer;
    IndexFactoryStorage factoryStorage;
    address factoryStorageAddress;

    address user = address(1);
    address owner = address(0x2);

    address wethAddress = address(0x1234);
    address vaultAddress = address(0x5678);

    function setUp() external {
        vm.startPrank(owner);

        factoryStorage = new IndexFactoryStorage();
        factoryStorage.initialize(
            payable(address(0)),
            address(0),
            address(0),
            0x0,
            address(0),
            wethAddress,
            address(0),
            address(0),
            address(0),
            address(0),
            vaultAddress
        );

        factoryStorage.setVault(vaultAddress);

        factoryStorageAddress = address(factoryStorage);

        indexFactoryBalancer = new IndexFactoryBalancer();
        indexFactoryBalancer.initialize(payable(address(factoryStorage)));

        vm.stopPrank();
    }

    function test_initialize_SuccessfulInitialization() public {
        assertEq(address(indexFactoryBalancer.factoryStorage()), factoryStorageAddress);
    }

    function testInitialize_RevertOnZeroAddress() public {
        IndexFactoryBalancer newBalancer = new IndexFactoryBalancer();

        vm.expectRevert("Invalid factory storage address");
        newBalancer.initialize(payable(address(0)));
    }

    function testWithdraw_Success() public {
        uint256 deposit = 5 ether;
        uint256 withdrawAmount = 3 ether;

        // Deposit Ether into contract
        vm.deal(address(indexFactoryBalancer), deposit);

        vm.startPrank(owner);
        indexFactoryBalancer.withdraw(withdrawAmount);
        vm.stopPrank();

        assertEq(owner.balance, withdrawAmount, "Owner did not receive the withdrawn Ether");
        assertEq(address(indexFactoryBalancer).balance, deposit - withdrawAmount, "Contract balance mismatch");
    }

    function testWithdraw_RevertOnInsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient balance");
        indexFactoryBalancer.withdraw(1 ether);
        vm.stopPrank();
    }

    function testRevertOnDirectEtherSend() public {
        vm.expectRevert("DoNotSendFundsDirectlyToTheContract");
        payable(address(indexFactoryBalancer)).transfer(1 ether);
    }

    function test_withdraw_FailWithdrawWhenBalanceIsInsufficient() public {
        vm.prank(owner);
        vm.expectRevert("Insufficient balance");
        indexFactoryBalancer.withdraw(1);
    }

    function testFailWithdraw_FailWhenTransferFails() public {
        vm.prank(owner);
        vm.deal(address(indexFactoryBalancer), 1 ether);
        vm.expectRevert("Transfer failed");
        indexFactoryBalancer.withdraw(1);
    }

    function test_pause_SuccessfulPause() public {
        vm.startPrank(owner);
        indexFactoryBalancer.pause();
        vm.stopPrank();
        assert(indexFactoryBalancer.paused());
    }

    function test_unpause_SuccessfulUnpause() public {
        vm.startPrank(owner);
        indexFactoryBalancer.pause();
        indexFactoryBalancer.unpause();
        vm.stopPrank();
        assertFalse(indexFactoryBalancer.paused());
    }

    function testFailPauseWithNonOwnerAddress() public {
        vm.startPrank(user);
        vm.expectRevert("Only owner can set the pause");
        indexFactoryBalancer.pause();
        vm.stopPrank();
    }

    function testFailUnpauseWithNonOwnerAddress() public {
        vm.startPrank(owner);
        indexFactoryBalancer.pause();
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("Only owner can set the unpause");
        indexFactoryBalancer.unpause();
        vm.stopPrank();
    }

    function test_failsSendETHDirectly() public {
        deal(user, 10 ether);

        vm.startPrank(user);
        vm.expectRevert("You can't send ether directly to this contact");
        address(indexFactoryBalancer).call{value: 10 ether}("");

        vm.stopPrank();
    }

    function testreIndexAndReweight() public {
        vm.startPrank(owner);

        address token1 = address(0x1001);
        address token2 = address(0x1002);
        address wethAddress = address(factoryStorage.weth());

        uint24 token1SwapFee = 3000;
        uint24 token2SwapFee = 10000;

        uint256 vaultToken1Balance = 1000 * 10 ** 18;
        uint256 vaultToken2Balance = 2000 * 10 ** 18;
        uint256 wethBalanceBefore = 5000 * 10 ** 18;

        vm.mockCall(
            address(factoryStorage.vault()),
            abi.encodeWithSelector(
                Vault.withdrawFunds.selector, token1, address(indexFactoryBalancer), vaultToken1Balance
            ),
            abi.encode(true)
        );
        vm.mockCall(
            address(factoryStorage.vault()),
            abi.encodeWithSelector(
                Vault.withdrawFunds.selector, token2, address(indexFactoryBalancer), vaultToken2Balance
            ),
            abi.encode(true)
        );

        vm.mockCall(
            address(factoryStorage.vault()),
            abi.encodeWithSelector(IERC20.balanceOf.selector, token1),
            abi.encode(vaultToken1Balance)
        );
        vm.mockCall(
            address(factoryStorage.vault()),
            abi.encodeWithSelector(IERC20.balanceOf.selector, token2),
            abi.encode(vaultToken2Balance)
        );

        vm.mockCall(
            wethAddress,
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(indexFactoryBalancer)),
            abi.encode(wethBalanceBefore)
        );

        indexFactoryBalancer.reIndexAndReweight();

        uint256 wethBalanceAfter = wethBalanceBefore;
        assertEq(
            IERC20(wethAddress).balanceOf(address(indexFactoryBalancer)),
            wethBalanceAfter,
            "WETH balance mismatch after reindexing"
        );

        vm.stopPrank();
    }

    function testFailReIndexAndReweight_RevertOnVaultWithdrawalFailure() public {
        vm.mockCall(
            vaultAddress,
            abi.encodeWithSelector(Vault.withdrawFunds.selector, address(0), address(indexFactoryBalancer), 100),
            abi.encode(false)
        );

        vm.startPrank(owner);
        vm.expectRevert("Vault withdrawal failed");
        indexFactoryBalancer.reIndexAndReweight();
        vm.stopPrank();
    }

    function testFailReceiveFunctionReverts() public {
        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vm.expectRevert("DoNotSendFundsDirectlyToTheContract");
        (bool success,) = address(indexFactoryBalancer).call{value: 1 ether}("");
        assertFalse(success, "Direct ETH transfer should fail");
        vm.stopPrank();
    }

    function testFailSwap_RevertOnTransferFailure() public {
        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.swapRouterV3.selector),
            abi.encode(address(0))
        );

        vm.mockCall(
            address(factoryStorage),
            abi.encodeWithSelector(factoryStorage.swapRouterV2.selector),
            abi.encode(address(0))
        );

        vm.startPrank(owner);
        vm.expectRevert("Transfer failed");
        SwapHelpers.swap(
            ISwapRouter(address(0)), IUniswapV2Router02(address(0)), 3000, address(0), address(0), 100, owner
        );
        vm.stopPrank();
    }
}
