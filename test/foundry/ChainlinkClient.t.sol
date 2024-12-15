// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/chainlink/ChainlinkClient.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";
import "@chainlink/contracts/src/v0.8/Chainlink.sol";

contract ChainlinkClientTest is Test, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    MockApiOracle private mockOracle;
    LinkTokenInterface private linkToken;

    mapping(bytes32 => address) internal s_pendingRequests;

    function setUp() public {
        linkToken = LinkTokenInterface(address(new LinkToken()));
        mockOracle = new MockApiOracle(address(linkToken));
        setChainlinkToken(address(linkToken));
        setChainlinkOracle(address(mockOracle));
    }

    function testBuildChainlinkRequest() public {
        bytes32 specId = "specId";
        address callbackAddr = address(this);
        bytes4 callbackFunctionSignature = this.fulfill.selector;

        Chainlink.Request memory req = buildChainlinkRequest(specId, callbackAddr, callbackFunctionSignature);

        assertEq(req.id, specId);
        assertEq(req.callbackAddress, callbackAddr);
        assertEq(req.callbackFunctionId, callbackFunctionSignature);
    }

    function testBuildOperatorRequest() public {
        bytes32 specId = "specId";
        bytes4 callbackFunctionSignature = this.fulfill.selector;

        Chainlink.Request memory req = buildOperatorRequest(specId, callbackFunctionSignature);

        assertEq(req.id, specId);
        assertEq(req.callbackAddress, address(this));
        assertEq(req.callbackFunctionId, callbackFunctionSignature);
    }

    function testSendChainlinkRequest() public {
        bytes32 specId = "specId";
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfill.selector);
        uint256 payment = 1 * LINK_DIVISIBILITY;

        bytes32 requestId = sendChainlinkRequest(req, payment);

        // assertTrue(s_pendingRequests[requestId] != address(0));
    }

    function testSendChainlinkRequestTo() public {
        bytes32 specId = "specId";
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfill.selector);
        uint256 payment = 1 * LINK_DIVISIBILITY;

        bytes32 requestId = sendChainlinkRequestTo(address(mockOracle), req, payment);

        // assertTrue(s_pendingRequests[requestId] != address(0));
    }

    function testGetNextRequestCount() public {
        uint256 initialCount = getNextRequestCount();
        sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );
        uint256 newCount = getNextRequestCount();

        assertEq(newCount, initialCount + 1);
    }

    function fulfill(bytes32 requestId, bytes32 data) public recordChainlinkFulfillment(requestId) {
        // Fulfillment logic
    }

    // -----------------------------------------------------------------------------------------------------------------------------

    function testAddChainlinkExternalRequest() public {
        bytes32 requestId = keccak256("externalRequest");
        address externalOracle = address(mockOracle);

        addChainlinkExternalRequest(externalOracle, requestId);

        assertEq(getPendingRequest(requestId), externalOracle);
    }

    function testCancelChainlinkRequest() public {
        bytes32 requestId = sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );

        uint256 expiration = block.timestamp + 1 days;
        vm.warp(block.timestamp + 2 days);

        cancelChainlinkRequest(requestId, 1 * LINK_DIVISIBILITY, this.fulfill.selector, expiration);

        assertEq(getPendingRequest(requestId), address(0));
    }

    function testPendingRequestsMapping() public {
        bytes32 requestId = sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );

        uint256 expiration = block.timestamp + 1 days;
        vm.warp(block.timestamp + 2 days);

        cancelChainlinkRequest(requestId, 1 * LINK_DIVISIBILITY, this.fulfill.selector, expiration);

        assertEq(getPendingRequest(requestId), address(0));
    }

    function testFailSendChainlinkRequestInvalidPayment() public {
        bytes32 specId = "specId";
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfill.selector);

        vm.expectRevert("unable to transferAndCall to oracle");
        sendChainlinkRequest(req, 0);
    }

    function testUnauthorizedFulfillment() public {
        bytes32 requestId = sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );

        vm.prank(address(0xdeadbeef));
        vm.expectRevert("Source must be the oracle of the request");
        fulfill(requestId, keccak256("data"));
    }
}
