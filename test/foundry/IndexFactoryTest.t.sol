// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../contracts/factory/IndexFactory.sol";
import "./OlympixUnitTest.sol";

contract IndexFactoryTest is OlympixUnitTest("IndexFactory") {
    IndexFactory indexFactory;

    function setUp() external {
        indexFactory = new IndexFactory();
        indexFactory.initialize(payable(address(new IndexFactoryStorage())));
    }

    function testUnpause() public {
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
}
