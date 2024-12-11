// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import "../../contracts/factory/IndexFactoryBalancer.sol";
import "../../contracts/factory/IndexFactoryStorage.sol";

contract IndexFactoryBalancerTest is Test {
    IndexFactoryBalancer indexFactoryBalancer;
    IndexFactoryStorage factoryStorage;
    address factoryStorageAddress;

    address user = address(1);
    address owner = address(2);

    function setUp() external {
        vm.startPrank(owner);
        factoryStorage = new IndexFactoryStorage();
        factoryStorageAddress = address(factoryStorage);
        indexFactoryBalancer = new IndexFactoryBalancer();
        indexFactoryBalancer.initialize(payable(factoryStorageAddress));
        vm.stopPrank();
    }

    function test_initialize_SuccessfulInitialization() public {
        assertEq(address(indexFactoryBalancer.factoryStorage()), factoryStorageAddress);
    }

    function testWithdraw() public {
        uint256 initialBalance = 10 ether;
        deal(address(indexFactoryBalancer), initialBalance);

        vm.prank(owner);
        indexFactoryBalancer.withdraw(initialBalance);
        uint256 ownerBalance = owner.balance;

        assertEq(ownerBalance, initialBalance);
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
}
