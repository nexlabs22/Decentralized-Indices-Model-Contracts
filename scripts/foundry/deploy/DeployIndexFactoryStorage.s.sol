// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../../contracts/factory/IndexFactoryStorage.sol";

contract DeployIndexFactoryStorage is Script {
    IndexFactoryStorage indexFactoryStorageImplementation;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address payable token = vm.envAddress("INDEX_TOKEN_ADDRESS");
        address functionsRouterAddress = vm.envAddress("FUNCTIONS_ROUTER_ADDRESS");
        bytes32 memory newDonId = vm.envBytes32("NEW_DON_ID");
        address toUsdPriceFeed = vm.envAddress("TO_USD_PRICE_FEED");
        address wethAddress = vm.envAddress("WETH_ADDRESS");
        address quoterAddress = vm.envAddress("QUOTER_ADDRESS");
        address swapRouterV3 = vm.envAddress("ROUTER_V3_ADDRESS");
        address factoryV3 = vm.envAddress("FACTORY_V3_ADDRESS");
        address swapRouterV2 = vm.envAddress("ROUTER_V2_ADDRESS");
        address factoryV2 = vm.envAddress("FACTORY_V2_ADDRESS");

        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);

        indexFactoryStorageImplementation = new IndexFactoryStorage();

        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,bytes32,address,address,address,address,address,address,address)",
            token,
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

    function setValues(address _feeReceiver, address _priceOracleAddress, address _vault, address _indexFactoryBalancer)
        public
    {
        indexFactoryStorageImplementation.setFeeReceiver(_feeReceiver);
        indexFactoryStorageImplementation.setPriceOracle(_priceOracleAddress);
        indexFactoryStorageImplementation.setVault(_vault);
        indexFactoryStorageImplementation.setFactoryBalancer(_indexFactoryBalancer);
    }
}
