// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {IndexFactory} from "../../../contracts/factory/IndexFactory.sol";
import {IndexFactoryBalancer} from "../../../contracts/factory/IndexFactoryBalancer.sol";
import {IndexFactoryStorage} from "../../../contracts/factory/IndexFactoryStorage.sol";
import {IndexToken} from "../../../contracts/token/IndexToken.sol";
import {Vault} from "../../../contracts/vault/Vault.sol";
import {PriceOracleByteCode} from "../../../contracts/test/PriceOracleByteCode.sol";

/**
 * @dev This script organizes deployment steps into separate functions
 * to reduce local variable usage in a single function body.
 */
contract DeployAllContracts is Script, PriceOracleByteCode {
    uint256 internal deployerPrivateKey;
    address internal functionsRouterAddress;
    bytes32 internal newDonId;
    address internal toUsdPriceFeed;
    address internal wethAddress;
    address internal quoterAddress;
    address internal swapRouterV3;
    address internal factoryV3;
    address internal swapRouterV2;
    address internal factoryV2;

    string internal tokenName;
    string internal tokenSymbol;
    uint256 internal feeRatePerDayScaled;
    address internal feeReceiver;
    uint256 internal supplyCeiling;

    address internal indexTokenProxy;
    address internal indexFactoryStorageProxy;
    address internal indexFactoryProxy;
    address internal indexFactoryBalancerProxy;
    address internal priceOracle;
    address internal vaultProxy;

    IndexToken internal indexTokenImplementation;
    ProxyAdmin internal indexTokenProxyAdmin;

    IndexFactoryStorage internal indexFactoryStorageImplementation;
    ProxyAdmin internal indexFactoryStorageProxyAdmin;

    IndexFactory internal indexFactoryImplementation;
    ProxyAdmin internal indexFactoryProxyAdmin;

    IndexFactoryBalancer internal indexFactoryBalancerImplementation;
    ProxyAdmin internal indexFactoryBalancerProxyAdmin;

    Vault internal vaultImplementation;
    ProxyAdmin internal vaultProxyAdmin;

    function run() external {
        // 2.1 Load environment vars
        readEnvVars();

        // 2.2 Start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // 2.3 Deploy everything step by step
        deployIndexToken();
        deployIndexFactoryStorage();
        deployIndexFactory();
        deployIndexFactoryBalancer();
        deployPriceOracle();
        deployVault();

        // 2.4 Set the necessary values after deployment
        setProxyValues();

        // 2.5 End broadcast
        vm.stopBroadcast();
    }

    function readEnvVars() internal {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        functionsRouterAddress = vm.envAddress("FUNCTIONS_ROUTER_ADDRESS");
        newDonId = vm.envBytes32("NEW_DON_ID");
        toUsdPriceFeed = vm.envAddress("TO_USD_PRICE_FEED");
        wethAddress = vm.envAddress("WETH_ADDRESS");
        quoterAddress = vm.envAddress("QUOTER_ADDRESS");
        swapRouterV3 = vm.envAddress("ROUTER_V3_ADDRESS");
        factoryV3 = vm.envAddress("FACTORY_V3_ADDRESS");
        swapRouterV2 = vm.envAddress("ROUTER_V2_ADDRESS");
        factoryV2 = vm.envAddress("FACTORY_V2_ADDRESS");

        tokenName = "Arbitrum Ecosystem Index";
        tokenSymbol = "ARBEI";
        feeRatePerDayScaled = vm.envUint("FEE_RATE_PER_DAY_SCALED");
        feeReceiver = vm.envAddress("FEE_RECEIVER");
        supplyCeiling = vm.envUint("SUPPLY_CEILING");
    }

    function deployIndexToken() internal {
        indexTokenProxyAdmin = new ProxyAdmin();
        indexTokenImplementation = new IndexToken();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256)",
            tokenName,
            tokenSymbol,
            feeRatePerDayScaled,
            feeReceiver,
            supplyCeiling
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(indexTokenImplementation), address(indexTokenProxyAdmin), initData);

        indexTokenProxy = address(proxy);

        console.log("///////// IndexToken //////////");
        console.log("IndexToken impl:", address(indexTokenImplementation));
        console.log("IndexToken proxy:", indexTokenProxy);
        console.log("IndexToken ProxyAdmin:", address(indexTokenProxyAdmin));
    }

    function deployIndexFactoryStorage() internal {
        indexFactoryStorageProxyAdmin = new ProxyAdmin();
        indexFactoryStorageImplementation = new IndexFactoryStorage();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,bytes32,address,address,address,address,address,address,address)",
            payable(indexTokenProxy),
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

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(indexFactoryStorageImplementation), address(indexFactoryStorageProxyAdmin), initData
        );

        indexFactoryStorageProxy = address(proxy);

        console.log("///////// IndexFactoryStorage //////////");
        console.log("IndexFactoryStorage impl:", address(indexFactoryStorageImplementation));
        console.log("IndexFactoryStorage proxy:", indexFactoryStorageProxy);
        console.log("IndexFactoryStorage ProxyAdmin:", address(indexFactoryStorageProxyAdmin));
    }

    function deployIndexFactory() internal {
        indexFactoryProxyAdmin = new ProxyAdmin();
        indexFactoryImplementation = new IndexFactory();

        bytes memory initData = abi.encodeWithSignature("initialize(address)", indexFactoryStorageProxy);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(indexFactoryImplementation), address(indexFactoryProxyAdmin), initData
        );

        indexFactoryProxy = address(proxy);

        console.log("///////// IndexFactory //////////");
        console.log("IndexFactory impl:", address(indexFactoryImplementation));
        console.log("IndexFactory proxy:", indexFactoryProxy);
        console.log("IndexFactory ProxyAdmin:", address(indexFactoryProxyAdmin));
    }

    function deployIndexFactoryBalancer() internal {
        indexFactoryBalancerProxyAdmin = new ProxyAdmin();
        indexFactoryBalancerImplementation = new IndexFactoryBalancer();

        bytes memory initData = abi.encodeWithSignature("initialize(address)", indexFactoryStorageProxy);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(indexFactoryBalancerImplementation), address(indexFactoryBalancerProxyAdmin), initData
        );

        indexFactoryBalancerProxy = address(proxy);

        console.log("///////// IndexFactoryBalancer //////////");
        console.log("IndexFactoryBalancer impl:", address(indexFactoryBalancerImplementation));
        console.log("IndexFactoryBalancer proxy:", indexFactoryBalancerProxy);
        console.log("IndexFactoryBalancer ProxyAdmin:", address(indexFactoryBalancerProxyAdmin));
    }

    function deployPriceOracle() internal {
        address deployed = deployByteCode(priceOracleByteCode);
        priceOracle = deployed;

        console.log("///////// PriceOracle //////////");
        console.log("PriceOracle deployed at:", priceOracle);
    }

    function deployVault() internal {
        vaultProxyAdmin = new ProxyAdmin();
        vaultImplementation = new Vault();

        bytes memory initData = abi.encodeWithSignature("initialize()");

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(vaultImplementation), address(vaultProxyAdmin), initData);

        vaultProxy = address(proxy);

        console.log("///////// Vault //////////");
        console.log("Vault impl:", address(vaultImplementation));
        console.log("Vault proxy:", vaultProxy);
        console.log("Vault ProxyAdmin:", address(vaultProxyAdmin));
    }

    function setProxyValues() internal {
        IndexToken(indexTokenProxy).setMinter(indexFactoryProxy);

        IndexFactoryStorage(indexFactoryStorageProxy).setFeeReceiver(feeReceiver);
        IndexFactoryStorage(indexFactoryStorageProxy).setPriceOracle(priceOracle);
        IndexFactoryStorage(indexFactoryStorageProxy).setVault(vaultProxy);
        IndexFactoryStorage(indexFactoryStorageProxy).setFactoryBalancer(indexFactoryBalancerProxy);

        Vault(vaultProxy).setOperator(indexFactoryProxy, true);
        Vault(vaultProxy).setOperator(indexFactoryBalancerProxy, true);
    }

    function deployByteCode(bytes memory bytecode) public returns (address) {
        address deployedContract;
        assembly {
            deployedContract := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        return deployedContract;
    }
}
