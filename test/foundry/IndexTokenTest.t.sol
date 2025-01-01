// SPDX-License-Identifier:
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "./ContractDeployer.sol";
import "../../contracts/token/IndexToken.sol";

contract IndexTokenTest is Test, ContractDeployer {
    function setUp() external {
        deployAllContracts();
    }

    function testPauseSuccessful() public {
        indexToken.pause();
        assertTrue(indexToken.paused(), "Factory should be paused");
    }

    function testPauseRevertNonOwnerCall() public {
        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.pause();
        assertFalse(indexToken.paused());
    }

    function testUnPauseSuccessful() public {
        indexToken.pause();

        indexToken.unpause();
        assertFalse(indexToken.paused());
    }

    function testUnPauseRevertNonOwnerCall() public {
        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.unpause();
    }

    function testSetMethodologist_Mutations() public {
        vm.startPrank(address(this));
        vm.expectRevert();
        indexToken.setMethodologist(address(0));
        address validMethodologist = address(0x1234);
        indexToken.setMethodologist(validMethodologist);
        assertEq(indexToken.methodologist(), validMethodologist);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.setMethodologist(validMethodologist);
        vm.stopPrank();
    }

    function testSetMethodology_Mutations() public {
        address validMethodologist = address(0x1234);
        indexToken.setMethodologist(validMethodologist);

        vm.startPrank(validMethodologist);
        vm.expectRevert("methodology cannot be empty");
        indexToken.setMethodology("");
        string memory validMethodology = "Balanced Portfolio";
        indexToken.setMethodology(validMethodology);
        assertEq(indexToken.methodology(), validMethodology);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("IndexToken: caller is not the methodologist");
        indexToken.setMethodology(validMethodology);
        vm.stopPrank();
    }

    function testSetFeeRate_Mutations() public {
        vm.startPrank(address(this));
        uint256 validFeeRate = 1000;
        indexToken.setFeeRate(validFeeRate);
        assertEq(indexToken.feeRatePerDayScaled(), validFeeRate);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.setFeeRate(validFeeRate);
        vm.stopPrank();
    }

    function testSetFeeReceiver_Mutations() public {
        vm.startPrank(address(this));
        vm.expectRevert();
        indexToken.setFeeReceiver(address(0));
        address validFeeReceiver = address(0x4567);
        indexToken.setFeeReceiver(validFeeReceiver);
        assertEq(indexToken.feeReceiver(), validFeeReceiver);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.setFeeReceiver(validFeeReceiver);
        vm.stopPrank();
    }

    function testSetMinter_Mutations() public {
        vm.startPrank(address(this));
        vm.expectRevert();
        indexToken.setMinter(address(0));
        address validMinter = address(0x7890);
        indexToken.setMinter(validMinter);
        assertEq(indexToken.minter(), validMinter);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.setMinter(validMinter);
        vm.stopPrank();
    }

    function testSetSupplyCeiling_Mutations() public {
        vm.startPrank(address(this));
        uint256 validSupplyCeiling = 1_000_000 ether;
        indexToken.setSupplyCeiling(validSupplyCeiling);
        assertEq(indexToken.supplyCeiling(), validSupplyCeiling);
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.setSupplyCeiling(validSupplyCeiling);
        vm.stopPrank();
    }

    function testToggleRestriction_Mutations() public {
        vm.startPrank(address(this));
        address user = address(0x9876);
        indexToken.toggleRestriction(user);
        assertTrue(indexToken.isRestricted(user));
        indexToken.toggleRestriction(user);
        assertFalse(indexToken.isRestricted(user));
        vm.stopPrank();

        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.toggleRestriction(user);
        vm.stopPrank();
    }

    function testMintToFeeReceiverRevert() public {
        vm.startPrank(add1);
        vm.expectRevert("Ownable: caller is not the owner");
        indexToken.mintToFeeReceiver();
    }
}
