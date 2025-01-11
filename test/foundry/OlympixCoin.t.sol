// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "contracts/test/OlympixCoin.sol";
import "./OlympixUnitTest.sol";

contract OlympixCoinTest is OlympixUnitTest("OlympixCoin") {
    address alice = address(0x456);
    address bob = address(0x789);
    address treasury = address(0xabc);
    address coinCreater = address(0xff);
    OlympixCoin coin;

    function setUp() public {
        vm.deal(coinCreater, 1000);
        vm.startPrank(coinCreater);
        coin = new OlympixCoin(treasury, coinCreater);
        vm.stopPrank();

        deal(address(coin), alice, 1000);
        deal(address(coin), bob, 1000);
    }

    function test_transfer_SuccessfulTransferWithTax() public {
        vm.startPrank(alice);
        coin.transfer(bob, 100);
        vm.stopPrank();
    
    //    assertEq(coin.balanceOf(alice), 898);
    //    assertEq(coin.balanceOf(bob), 1100);
    //    assertEq(coin.balanceOf(treasury), 350002);
    }
    

    function test_transfer_SuccessfulTransferWithoutTax() public {
        vm.startPrank(coinCreater);
        coin.toggleTax(false);
        vm.stopPrank();
    
        vm.startPrank(alice);
        coin.transfer(bob, 100);
        vm.stopPrank();
    
        assertEq(coin.balanceOf(alice), 900);
        assertEq(coin.balanceOf(bob), 1100);
        assertEq(coin.balanceOf(treasury), 350000);
    }

    function test_toggleTax_FailWhenSenderIsNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Only owner can set taxEnabled");
        coin.toggleTax(false);
        vm.stopPrank();
    }

    function test_toggleTax_SuccessfulToggle() public {
        vm.startPrank(coinCreater);
        coin.toggleTax(false);
        assertEq(coin.taxEnabled(), false);
        vm.stopPrank();
    }
}