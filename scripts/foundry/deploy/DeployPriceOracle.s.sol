// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

import "../../../contracts/factory/PriceOracle.sol";

contract DeployPriceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        PriceOracle priceOracle = new PriceOracle();

        console.log("PriceOracle implementation deployed at:", address(priceOracle));

        vm.stopBroadcast();
    }
}
