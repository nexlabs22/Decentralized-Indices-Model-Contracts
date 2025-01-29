// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IndexFactory} from "../../contracts/factory/IndexFactory.sol";
import {IndexToken} from "../../contracts/token/IndexToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OnchainTest is Script {
    IndexToken indexToken;

    address user = 0x11a8E23DAfbE058e9758c899dAEe0e43f287A96D;
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdt = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    // address user = 0x51256F5459C1DdE0C794818AF42569030901a098;
    // address weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    // address usdt = 0xE8888fE3Bde6f287BDd0922bEA6E0bF6e5f418e7;

    address indexFactoryProxy = 0xC261547547fb4b108db504FE200e20Db7612D5E9;
    address indexTokenProxy = 0x4386741db5Aadec9201c997b9fD197b598ef1323;
    // address indexFactoryProxy = vm.envAddress("ARBITRUM_INDEX_FACTORY_PROXY_ADDRESS");
    // address indexTokenProxy = vm.envAddress("ARBITRUM_INDEX_TOKEN_PROXY_ADDRESS");
    // address indexFactoryProxy = vm.envAddress("SEPOLIA_INDEX_FACTORY_PROXY_ADDRESS");
    // address indexTokenProxy = vm.envAddress("SEPOLIA_INDEX_TOKEN_PROXY_ADDRESS");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        indexToken = IndexToken(indexTokenProxy);

        issuanceAndRedemptionWithEth();

        // issuanceAndRedemptionWithUsdt();

        vm.stopBroadcast();
    }

    function issuanceAndRedemptionWithEth() public {
        // IndexFactory(payable(indexFactoryProxy)).issuanceIndexTokensWithEth{value: (1e14 * 1001) / 1000}(1e14);

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdt;
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        IndexFactory(payable(indexFactoryProxy)).redemption(
            indexToken.balanceOf(address(user)), address(weth), path, fees, 3
        );
    }

    function issuanceAndRedemptionWithUsdt() public {
        IERC20(usdt).approve(address(indexFactoryProxy), 1001e18);

        address[] memory path0 = new address[](2);
        path0[0] = usdt;
        path0[1] = weth;
        uint24[] memory fees0 = new uint24[](1);
        fees0[0] = 3000;

        IndexFactory(payable(indexFactoryProxy)).issuanceIndexTokens(address(usdt), path0, fees0, 100e18, 3000);

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdt;
        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        IndexFactory(payable(indexFactoryProxy)).redemption(
            indexToken.balanceOf(address(user)), address(weth), path, fees, 3
        );
    }
}
