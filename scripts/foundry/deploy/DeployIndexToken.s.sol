// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../../contracts/token/IndexToken.sol";

contract DeployIndexToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory tokenName = "Arbitrum Ecosystem Index";
        string memory tokenSymbol = "ARBEI";
        uint256 feeRatePerDayScaled = vm.envUint("FEE_RATE_PER_DAY_SCALED");
        address feeReceiver = vm.envAddress("FEE_RECEIVER");
        uint256 supplyCeiling = vm.envUint("SUPPLY_CEILING");

        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin proxyAdmin = new ProxyAdmin();

        IndexToken indexTokenImplementation = new IndexToken();

        bytes memory data = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256)",
            tokenName,
            tokenSymbol,
            feeRatePerDayScaled,
            feeReceiver,
            supplyCeiling
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(indexTokenImplementation), address(proxyAdmin), data);

        console.log("IndexToken implementation deployed at:", address(indexTokenImplementation));
        console.log("IndexToken proxy deployed at:", address(proxy));
        console.log("ProxyAdmin for IndexToken deployed at:", address(proxyAdmin));

        vm.stopBroadcast();
    }
}
