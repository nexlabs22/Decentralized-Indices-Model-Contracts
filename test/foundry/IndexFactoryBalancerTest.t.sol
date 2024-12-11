// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import "../../contracts/factory/IndexFactoryBalancer.sol";
import "../../contracts/factory/IndexFactoryStorage.sol";

contract IndexFactoryBalancerTest is Test {
    IndexFactoryBalancer indexFactoryBalancer;
    IndexFactoryStorage factoryStorage;
    address factoryStorageAddress;

    function setUp() external {
        factoryStorage = new IndexFactoryStorage();
        factoryStorageAddress = address(factoryStorage);
        indexFactoryBalancer = new IndexFactoryBalancer();
        indexFactoryBalancer.initialize(payable(factoryStorageAddress));
    }

    function test_initialize_SuccessfulInitialization() public {
        assertEq(address(indexFactoryBalancer.factoryStorage()), factoryStorageAddress);
    }

    function test_withdraw_FailWithdrawWhenBalanceIsInsufficient() public {
        vm.expectRevert("Insufficient balance");
        indexFactoryBalancer.withdraw(1);
    }

    function test_withdraw_FailWhenTransferFails() public {
        vm.deal(address(indexFactoryBalancer), 1 ether);
        vm.expectRevert("Transfer failed");
        indexFactoryBalancer.withdraw(1);
    }

    function test_pause_SuccessfulPause() public {
        indexFactoryBalancer.pause();
        assert(indexFactoryBalancer.paused());
    }

    function test_unpause_SuccessfulUnpause() public {
        indexFactoryBalancer.pause();
        indexFactoryBalancer.unpause();
        assertFalse(indexFactoryBalancer.paused());
    }
}
