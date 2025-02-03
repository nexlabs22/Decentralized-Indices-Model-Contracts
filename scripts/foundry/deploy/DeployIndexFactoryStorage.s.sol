// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../../contracts/factory/IndexFactoryStorage.sol";

contract DeployIndexFactoryStorage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address token = vm.envAddress("ARBITRUM_INDEX_TOKEN_PROXY_ADDRESS");
        address functionsRouterAddress = vm.envAddress("ARBITRUM_FUNCTIONS_ROUTER_ADDRESS");
        bytes32 newDonId = vm.envBytes32("ARBITRUM_NEW_DON_ID");
        address toUsdPriceFeed = vm.envAddress("ARBITRUM_TO_USD_PRICE_FEED");
        address wethAddress = vm.envAddress("ARBITRUM_WETH_ADDRESS");
        address quoterAddress = vm.envAddress("ARBITRUM_QUOTER_ADDRESS");
        address swapRouterV3 = vm.envAddress("ARBITRUM_ROUTER_V3_ADDRESS");
        address factoryV3 = vm.envAddress("ARBITRUM_FACTORY_V3_ADDRESS");
        address swapRouterV2 = vm.envAddress("ARBITRUM_ROUTER_V2_ADDRESS");
        address factoryV2 = vm.envAddress("ARBITRUM_FACTORY_V2_ADDRESS");

        // address payable token = vm.envAddress("SEPOLIA_INDEX_TOKEN_PROXY_ADDRESS");
        // address functionsRouterAddress = vm.envAddress("SEPOLIA_FUNCTIONS_ROUTER_ADDRESS");
        // bytes32 memory newDonId = vm.envBytes32("SEPOLIA_NEW_DON_ID");
        // address toUsdPriceFeed = vm.envAddress("SEPOLIA_TO_USD_PRICE_FEED");
        // address wethAddress = vm.envAddress("SEPOLIA_WETH_ADDRESS");
        // address quoterAddress = vm.envAddress("SEPOLIA_QUOTER_ADDRESS");
        // address swapRouterV3 = vm.envAddress("SEPOLIA_ROUTER_V3_ADDRESS");
        // address factoryV3 = vm.envAddress("SEPOLIA_FACTORY_V3_ADDRESS");
        // address swapRouterV2 = vm.envAddress("SEPOLIA_ROUTER_V2_ADDRESS");
        // address factoryV2 = vm.envAddress("SEPOLIA_FACTORY_V2_ADDRESS");

        ProxyAdmin proxyAdmin = new ProxyAdmin();

        IndexFactoryStorage indexFactoryStorageImplementation = new IndexFactoryStorage();

        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,bytes32,address,address,address,address,address,address,address)",
            payable(token),
            functionsRouterAddress,
            newDonId,
            toUsdPriceFeed,
            wethAddress,
            quoterAddress,
            swapRouterV3,
            factoryV3,
            swapRouterV2,
            factoryV2
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(indexFactoryStorageImplementation), address(proxyAdmin), data);

        console.log("IndexFactoryStorage implementation deployed at:", address(indexFactoryStorageImplementation));
        console.log("IndexFactoryStorage proxy deployed at:", address(proxy));
        console.log("ProxyAdmin for IndexFactoryStorage deployed at:", address(proxyAdmin));

        vm.stopBroadcast();
    }
}
