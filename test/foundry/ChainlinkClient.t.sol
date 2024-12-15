// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../contracts/chainlink/ChainlinkClient.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";
import "@chainlink/contracts/src/v0.8/Chainlink.sol";
import "@chainlink/contracts/src/v0.8/Chainlink.sol";
import "@chainlink/contracts/src/v0.8/interfaces/ENSInterface.sol";
import "@chainlink/contracts/src/v0.8/vendor/ENSResolver.sol";

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

    // -----------------------------------------------------------------------------------------------------------------------------

    function testSetPublicChainlinkToken() public {
        address mockLinkAddress = address(linkToken);
        MockPointerInterface mockPointer = new MockPointerInterface(mockLinkAddress);

        vm.mockCall(
            0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571,
            abi.encodeWithSelector(PointerInterface.getAddress.selector),
            abi.encode(mockLinkAddress)
        );

        setPublicChainlinkToken();
        assertEq(chainlinkTokenAddress(), mockLinkAddress);
    }

    function testDuplicateRequests() public {
        bytes32 requestId = sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );

        vm.expectRevert("Request is already pending");
        addChainlinkExternalRequest(address(mockOracle), requestId);
    }

    function testFulfillNonExistentRequest() public {
        bytes32 requestId = keccak256("nonexistent");

        vm.expectRevert("Source must be the oracle of the request");
        fulfill(requestId, keccak256("data"));
    }

    function testFulfillInvalidOracle() public {
        bytes32 requestId = sendChainlinkRequest(
            buildChainlinkRequest("specId", address(this), this.fulfill.selector), 1 * LINK_DIVISIBILITY
        );

        vm.prank(address(0xdeadbeef));
        vm.expectRevert("Source must be the oracle of the request");
        fulfill(requestId, keccak256("data"));
    }

    // function testUseChainlinkWithENS() public {
    //     MockENS mockENS = new MockENS();
    //     MockENSResolver mockResolver = new MockENSResolver();

    //     bytes32 linkNode = keccak256(abi.encodePacked("mockNode", keccak256("link")));
    //     mockENS.setResolver(linkNode, address(mockResolver));
    //     mockResolver.setAddr(linkNode, address(linkToken));

    //     useChainlinkWithENS(address(mockENS), keccak256("mockNode"));

    //     assertEq(chainlinkTokenAddress(), address(linkToken));
    // }

    // function testUpdateChainlinkOracleWithENS() public {
    //     MockENS mockENS = new MockENS();
    //     MockENSResolver mockResolver = new MockENSResolver();

    //     bytes32 oracleNode = keccak256(abi.encodePacked("mockNode", keccak256("oracle")));
    //     mockENS.setResolver(oracleNode, address(mockResolver));
    //     mockResolver.setAddr(oracleNode, address(mockOracle));

    //     updateChainlinkOracleWithENS();

    //     assertEq(chainlinkOracleAddress(), address(mockOracle));
    // }

    function testChainlinkTokenAddress() public {
        assertEq(chainlinkTokenAddress(), address(linkToken));
    }

    function testChainlinkOracleAddress() public {
        assertEq(chainlinkOracleAddress(), address(mockOracle));
    }
}

contract MockPointerInterface is PointerInterface {
    address public mockAddress;

    constructor(address _mockAddress) {
        mockAddress = _mockAddress;
    }

    function getAddress() external view override returns (address) {
        return mockAddress;
    }
}

contract MockENS is ENSInterface {
    mapping(bytes32 => address) private resolvers;

    function setResolver(bytes32 node, address resolver) public {
        resolvers[node] = resolver;
    }

    function resolver(bytes32 node) external view override returns (address) {
        return resolvers[node];
    }

    function owner(bytes32 node) external view override returns (address) {
        return address(0);
    }

    function setOwner(bytes32 node, address owner) external override {}

    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external override {}

    function setTTL(bytes32 node, uint64 ttl) external override {}

    function ttl(bytes32 node) external view override returns (uint64) {
        return 0;
    }
}

contract MockENSResolver is ENSResolver_Chainlink {
    mapping(bytes32 => address) private addresses;

    function setAddr(bytes32 node, address addr) public {
        addresses[node] = addr;
    }

    function addr(bytes32 node) public view override returns (address) {
        return addresses[node];
    }
}
