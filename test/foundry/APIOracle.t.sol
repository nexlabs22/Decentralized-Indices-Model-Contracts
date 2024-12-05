// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/test/MockApiOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract MockApiOracleTest is Test {
    MockApiOracle oracle;
    LinkTokenInterface linkToken;
    address linkTokenAddress = address(0x123); // Mock LINK token address

    function setUp() public {
        linkToken = LinkTokenInterface(linkTokenAddress);
        oracle = new MockApiOracle(linkTokenAddress);
    }

    function testOracleRequest() public {
        bytes32 specId = keccak256("specId");
        address callbackAddress = address(this);
        bytes4 callbackFunctionId = bytes4(keccak256("callbackFunction(bytes32,bytes32)"));
        uint256 payment = 1 ether;
        uint256 nonce = 1;
        uint256 dataVersion = 1;
        bytes memory data = "test data";

        vm.prank(linkTokenAddress);
        oracle.oracleRequest(address(this), payment, specId, callbackAddress, callbackFunctionId, nonce, dataVersion, data);

        // Add assertions to verify the request was stored correctly
    }

    

    
}
