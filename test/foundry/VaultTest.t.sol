// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/vault/Vault.sol";
import "./OlympixUnitTest.sol";

contract VaultTest is Test {
    Vault vault;

    function setUp() external {
        vault = new Vault();
        vault.initialize();
    }

    function test_withdrawFunds_FailWhenCallerIsNotOperator() public {
        address operator = address(0x1);
        vault.setOperator(operator, true);

        address token = address(0x2);
        address to = address(0x3);
        uint256 amount = 1 ether;

        vm.startPrank(address(0x4));
        vm.expectRevert("NexVault: caller is not an operator");
        vault.withdrawFunds(token, to, amount);
        vm.stopPrank();
    }

    function test_withdrawFunds_FailWhenTokenAddressIsZero() public {
        address operator = address(0x1);
        vault.setOperator(operator, true);

        address token = address(0);
        address to = address(0x3);
        uint256 amount = 1 ether;

        vm.startPrank(operator);
        vm.expectRevert("NexVault: token address is zero");
        vault.withdrawFunds(token, to, amount);
        vm.stopPrank();
    }

    function test_withdrawFunds_FailWhenRecipientAddressIsZero() public {
        address operator = address(0x1);
        vault.setOperator(operator, true);

        address token = address(0x2);
        address to = address(0);
        uint256 amount = 1 ether;

        vm.startPrank(operator);
        vm.expectRevert("NexVault: recipient address is zero");
        vault.withdrawFunds(token, to, amount);
        vm.stopPrank();
    }

    function test_withdrawFunds_FailWhenAmountIsZero() public {
        address operator = address(0x1);
        vault.setOperator(operator, true);

        address token = address(0x2);
        address to = address(0x3);
        uint256 amount = 0;

        vm.startPrank(operator);
        vm.expectRevert("NexVault: amount is zero");
        vault.withdrawFunds(token, to, amount);
        vm.stopPrank();
    }
}
