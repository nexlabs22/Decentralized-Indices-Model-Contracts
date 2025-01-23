// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

import {IndexToken} from "../../../contracts/token/IndexToken.sol";
import {IndexFactoryStorage} from "../../../contracts/factory/IndexFactoryStorage.sol";
import {Vault} from "../../../contracts/vault/Vault.sol";

contract SetValues is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address indexTokenProxy = vm.envAddress("INDEX_TOKEN_PROXY_ADDRESS");
        address indexFactoryStorageProxy = vm.envAddress("INDEX_FACTORY_STORAGE_PROXY_ADDRESS");
        address vaultProxy = vm.envAddress("VAULT_PROXY_ADDRESS");

        address indexFactoryProxy = vm.envAddress("INDEX_FACTORY_PROXY_ADDRESS");
        address indexFactoryBalancerProxy = vm.envAddress("INDEX_FACTORY_BALANCER_PROXY_ADDRESS");
        address priceOracle = vm.envAddress("PRICE_ORACLE_ADDRESS");
        address feeReceiver = vm.envAddress("FEE_RECEIVER");

        vm.startBroadcast(deployerPrivateKey);

        IndexToken(indexTokenProxy).setMinter(indexFactoryProxy);

        IndexFactoryStorage(indexFactoryStorageProxy).setFeeReceiver(feeReceiver);
        IndexFactoryStorage(indexFactoryStorageProxy).setPriceOracle(priceOracle);
        IndexFactoryStorage(indexFactoryStorageProxy).setVault(vaultProxy);
        IndexFactoryStorage(indexFactoryStorageProxy).setFactoryBalancer(indexFactoryBalancerProxy);

        Vault(vaultProxy).setOperator(indexFactoryProxy);
        Vault(vaultProxy).setOperator(indexFactoryBalancerProxy);

        vm.stopBroadcast();

        console.log("SetValues script finished. Key addresses used:");
        console.log("IndexTokenProxy:            ", indexTokenProxy);
        console.log("IndexFactoryStorageProxy:   ", indexFactoryStorageProxy);
        console.log("VaultProxy:                 ", vaultProxy);
        console.log("IndexFactoryProxy:          ", indexFactoryProxy);
        console.log("IndexFactoryBalancerProxy:  ", indexFactoryBalancerProxy);
        console.log("PriceOracle:                ", priceOracle);
        console.log("FeeReceiver:                ", feeReceiver);
    }
}
