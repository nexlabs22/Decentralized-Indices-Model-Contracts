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
}

