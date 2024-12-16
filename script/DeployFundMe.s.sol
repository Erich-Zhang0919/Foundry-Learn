// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { FundMe } from "../src/FundMe.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function deployFundMe() public returns (FundMe, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return (fundMe, helperConfig);
    }

    function run() external returns (FundMe, HelperConfig) {
        return deployFundMe();
    }
    // function run() external returns (FundMe) {
    //     HelperConfig config = new HelperConfig();
    //     address ethUsdPriceFeed = config.activeNetworkConfig();

    //     // After Boardcast
    //     vm.startBroadcast();
    //     FundMe fundMe = new FundMe(ethUsdPriceFeed);
    //     vm.startBroadcast();
    //     return fundMe;

    // }
}