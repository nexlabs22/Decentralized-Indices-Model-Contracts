// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {IndexFactory} from "../../../contracts/factory/IndexFactory.sol";
import {IndexFactoryBalancer} from "../../../contracts/factory/IndexFactoryBalancer.sol";
import {IndexFactoryStorage} from "../../../contracts/factory/IndexFactoryStorage.sol";
import {PriceOracle} from "../../../contracts/factory/PriceOracle.sol";
import {IndexToken} from "../../../contracts/token/IndexToken.sol";
import {Vault} from "../../../contracts/vault/Vault.sol";

contract DeployAllContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address functionsRouterAddress = vm.envAddress("FUNCTIONS_ROUTER_ADDRESS");
        bytes32 newDonId = vm.envBytes32("NEW_DON_ID");
        address toUsdPriceFeed = vm.envAddress("TO_USD_PRICE_FEED");
        address wethAddress = vm.envAddress("WETH_ADDRESS");
        address quoterAddress = vm.envAddress("QUOTER_ADDRESS");
        address swapRouterV3 = vm.envAddress("ROUTER_V3_ADDRESS");
        address factoryV3 = vm.envAddress("FACTORY_V3_ADDRESS");
        address swapRouterV2 = vm.envAddress("ROUTER_V2_ADDRESS");
        address factoryV2 = vm.envAddress("FACTORY_V2_ADDRESS");

        string memory tokenName = "Arbitrum Ecosystem Index";
        string memory tokenSymbol = "ARBEI";
        uint256 feeRatePerDayScaled = vm.envUint("FEE_RATE_PER_DAY_SCALED");
        address feeReceiver = vm.envAddress("FEE_RECEIVER");
        uint256 supplyCeiling = vm.envUint("SUPPLY_CEILING");

        vm.startBroadcast(deployerPrivateKey);

        // ----------------------------------------------------------------
        ///////////
        // 1) Deploy IndexToken (Proxy)
        ///////////
        // ----------------------------------------------------------------
        ProxyAdmin indexTokenProxyAdmin = new ProxyAdmin(msg.sender);

        IndexToken indexTokenImplementation = new IndexToken();
        bytes memory indexTokenData = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256)",
            tokenName,
            tokenSymbol,
            feeRatePerDayScaled,
            feeReceiver,
            supplyCeiling
        );

        TransparentUpgradeableProxy indexTokenProxy = new TransparentUpgradeableProxy(
            address(indexTokenImplementation), address(indexTokenProxyAdmin), indexTokenData
        );

        console.log("///////// IndexToken //////////");
        console.log("IndexToken impl:", address(indexTokenImplementation));
        console.log("IndexToken proxy:", address(indexTokenProxy));
        console.log("IndexToken ProxyAdmin:", address(indexTokenProxyAdmin));

        // ----------------------------------------------------------------
        ///////////
        // 2) Deploy IndexFactoryStorage (Proxy)
        ///////////
        // ----------------------------------------------------------------
        ProxyAdmin indexFactoryStorageProxyAdmin = new ProxyAdmin(msg.sender);

        IndexFactoryStorage indexFactoryStorageImplementation = new IndexFactoryStorage();
        bytes memory indexFactoryStorageData = abi.encodeWithSignature(
            "initialize(address,address,bytes32,address,address,address,address,address,address,address)",
            payable(address(indexTokenProxy)),
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

        TransparentUpgradeableProxy indexFactoryStorageProxy = new TransparentUpgradeableProxy(
            address(indexFactoryStorageImplementation), address(indexFactoryStorageProxyAdmin), indexFactoryStorageData
        );

        console.log("///////// IndexFactoryStorage //////////");
        console.log("IndexFactoryStorage impl:", address(indexFactoryStorageImplementation));
        console.log("IndexFactoryStorage proxy:", address(indexFactoryStorageProxy));
        console.log("IndexFactoryStorage ProxyAdmin:", address(indexFactoryStorageProxyAdmin));

        // ----------------------------------------------------------------
        ///////////
        // 3) Deploy IndexFactory (Proxy)
        ///////////
        // ----------------------------------------------------------------
        ProxyAdmin indexFactoryProxyAdmin = new ProxyAdmin(msg.sender);

        IndexFactory indexFactoryImplementation = new IndexFactory();
        bytes memory indexFactoryData =
            abi.encodeWithSignature("initialize(address)", address(indexFactoryStorageProxy));

        TransparentUpgradeableProxy indexFactoryProxy = new TransparentUpgradeableProxy(
            address(indexFactoryImplementation), address(indexFactoryProxyAdmin), indexFactoryData
        );

        console.log("///////// IndexFactory //////////");
        console.log("IndexFactory impl:", address(indexFactoryImplementation));
        console.log("IndexFactory proxy:", address(indexFactoryProxy));
        console.log("IndexFactory ProxyAdmin:", address(indexFactoryProxyAdmin));

        // ----------------------------------------------------------------
        ///////////
        // 4) Deploy IndexFactoryBalancer (Proxy)
        ///////////
        // ----------------------------------------------------------------
        ProxyAdmin indexFactoryBalancerProxyAdmin = new ProxyAdmin(msg.sender);

        IndexFactoryBalancer indexFactoryBalancerImplementation = new IndexFactoryBalancer();
        bytes memory indexFactoryBalancerData =
            abi.encodeWithSignature("initialize(address)", address(indexFactoryStorageProxy));

        TransparentUpgradeableProxy indexFactoryBalancerProxy = new TransparentUpgradeableProxy(
            address(indexFactoryBalancerImplementation),
            address(indexFactoryBalancerProxyAdmin),
            indexFactoryBalancerData
        );

        console.log("///////// IndexFactoryBalancer //////////");
        console.log("IndexFactoryBalancer impl:", address(indexFactoryBalancerImplementation));
        console.log("IndexFactoryBalancer proxy:", address(indexFactoryBalancerProxy));
        console.log("IndexFactoryBalancer ProxyAdmin:", address(indexFactoryBalancerProxyAdmin));

        // ----------------------------------------------------------------
        ///////////
        // 5) Deploy PriceOracle (Direct)
        ///////////
        // ----------------------------------------------------------------
        PriceOracle priceOracle = new PriceOracle();

        console.log("///////// PriceOracle //////////");
        console.log("PriceOracle deployed at:", address(priceOracle));

        // ----------------------------------------------------------------
        ///////////
        // 6) Deploy Vault (Proxy)
        ///////////
        // ----------------------------------------------------------------
        ProxyAdmin vaultProxyAdmin = new ProxyAdmin(msg.sender);

        Vault vaultImplementation = new Vault();
        bytes memory vaultData = abi.encodeWithSignature("initialize()");

        TransparentUpgradeableProxy vaultProxy =
            new TransparentUpgradeableProxy(address(vaultImplementation), address(vaultProxyAdmin), vaultData);

        console.log("///////// Vault //////////");
        console.log("Vault impl:", address(vaultImplementation));
        console.log("Vault proxy:", address(vaultProxy));
        console.log("Vault ProxyAdmin:", address(vaultProxyAdmin));

        // ----------------------------------------------------------------
        ///////////
        // 7) Set Values via Proxy
        ///////////
        // ----------------------------------------------------------------
        IndexToken(address(indexTokenProxy)).setMinter(address(indexFactoryProxy));

        IndexFactoryStorage(address(indexFactoryStorageProxy)).setFeeReceiver(feeReceiver);
        IndexFactoryStorage(address(indexFactoryStorageProxy)).setPriceOracle(address(priceOracle));
        IndexFactoryStorage(address(indexFactoryStorageProxy)).setVault(address(vaultProxy));
        IndexFactoryStorage(address(indexFactoryStorageProxy)).setFactoryBalancer(address(indexFactoryBalancerProxy));

        Vault(address(vaultProxy)).setOperator(address(indexFactoryProxy));
        Vault(address(vaultProxy)).setOperator(address(indexFactoryBalancerProxy));

        vm.stopBroadcast();
    }
}
