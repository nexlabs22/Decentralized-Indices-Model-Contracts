// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IndexFactory} from "../../contracts/factory/IndexFactory.sol";
import {IndexToken} from "../../contracts/token/IndexToken.sol";

contract OnchainTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address user = 0x51256F5459C1DdE0C794818AF42569030901a098;
        address weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        address usdt = 0xE8888fE3Bde6f287BDd0922bEA6E0bF6e5f418e7;

        address indexFactoryProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_PROXY_ADDRESS");
        address indexTokenProxy = vm.envAddress("SEPOLIA_INDEX_TOKEN_PROXY_ADDRESS");

        IndexToken indexToken = IndexToken(indexTokenProxy);

        vm.startBroadcast(deployerPrivateKey);

        IndexFactory(payable(indexFactoryProxy)).issuanceIndexTokensWithEth{value: (1e15 * 1001) / 1000}(1e15);

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdt;
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        IndexFactory(payable(indexFactoryProxy)).redemption(
            indexToken.balanceOf(address(user)), address(weth), path, fees, 3
        );

        vm.stopBroadcast();
    }
}
