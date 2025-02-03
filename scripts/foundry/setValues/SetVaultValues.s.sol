// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

import {Vault} from "../../../contracts/vault/Vault.sol";

contract SetIndexTokenValues is Script {
    // Mainnet
    address indexFactoryProxy = vm.envAddress("ARBITRUM_INDEX_FACTORY_PROXY_ADDRESS");
    address indexFactoryBalancerProxy = vm.envAddress("ARBITRUM_INDEX_FACTORY_BALANCER_PROXY_ADDRESS");
    address vaultProxy = vm.envAddress("ARBITRUM_VAULT_PROXY_ADDRESS");

    // Testnet
    // address indexFactoryProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_PROXY_ADDRESS");
    // address indexFactoryBalancerProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_BALANCER_PROXY_ADDRESS");
    // address vaultProxy = vm.envAddress("SEPOLIA_VAULT_PROXY_ADDRESS");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Vault(vaultProxy).setOperator(indexFactoryProxy, true);
        Vault(vaultProxy).setOperator(indexFactoryBalancerProxy, true);

        vm.stopBroadcast();

        console.log("Values set successfully.");
    }
}
