// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

import {IndexFactoryStorage} from "../../../contracts/factory/IndexFactoryStorage.sol";

contract SetIndexTokenValues is Script {
    // Mainnet
    address indexFactoryStorageProxy = vm.envAddress("ARBITRUM_INDEX_FACTORY_STORAGE_PROXY_ADDRESS");
    address vaultProxy = vm.envAddress("ARBITRUM_VAULT_PROXY_ADDRESS");
    address indexFactoryBalancerProxy = vm.envAddress("ARBITRUM_INDEX_FACTORY_BALANCER_PROXY_ADDRESS");
    address priceOracle = vm.envAddress("ARBITRUM_PRICE_ORACLE_ADDRESS");
    address feeReceiver = vm.envAddress("ARBITRUM_FEE_RECEIVER");

    // Testnet
    // address indexFactoryStorageProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_STORAGE_PROXY_ADDRESS");
    // address vaultProxy = vm.envAddress("SEPOLIA_VAULT_PROXY_ADDRESS");
    // address indexFactoryBalancerProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_BALANCER_PROXY_ADDRESS");
    // address priceOracle = vm.envAddress("SEPOLIA_PRICE_ORACLE_ADDRESS");
    // address feeReceiver = vm.envAddress("SEPOLIA_FEE_RECEIVER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IndexFactoryStorage(indexFactoryStorageProxy).setFeeReceiver(feeReceiver);
        IndexFactoryStorage(indexFactoryStorageProxy).setPriceOracle(priceOracle);
        IndexFactoryStorage(indexFactoryStorageProxy).setVault(vaultProxy);
        IndexFactoryStorage(indexFactoryStorageProxy).setFactoryBalancer(indexFactoryBalancerProxy);

        vm.stopBroadcast();

        console.log("Values set successfully.");
    }
}
