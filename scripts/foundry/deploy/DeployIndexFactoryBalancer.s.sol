// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../../contracts/factory/IndexFactoryBalancer.sol";

contract DeployIndexFactoryBalancer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // address indexFactoryStorageAddress = vm.envAddress("SEPOLIA_INDEX_FACTORY_STORAGE_PROXY_ADDRESS");
        address indexFactoryStorageAddress = vm.envAddress("ARBITRUM_INDEX_FACTORY_STORAGE_PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin proxyAdmin = new ProxyAdmin();

        IndexFactoryBalancer indexFactoryBalancerImplementation = new IndexFactoryBalancer();

        bytes memory data = abi.encodeWithSignature("initialize(address)", indexFactoryStorageAddress);

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(indexFactoryBalancerImplementation), address(proxyAdmin), data);

        console.log("IndexFactoryBalancer implementation deployed at:", address(indexFactoryBalancerImplementation));
        console.log("IndexFactoryBalancer proxy deployed at:", address(proxy));
        console.log("ProxyAdmin for IndexFactoryBalancer deployed at:", address(proxyAdmin));

        vm.stopBroadcast();
    }
}
