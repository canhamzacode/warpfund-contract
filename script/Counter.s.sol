// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WarpFund} from "../src/FundMe.sol";

contract DeployWarpFund is Script {
    WarpFund public fundMe;

    function setUp() public {
        console.log("Deploying WarpFund");
        string[] memory categories = new string[](3);
        categories[0] = "Health";
        categories[1] = "Education";
        categories[2] = "Environment";
        fundMe.setCategories(categories);
    }

    function run() public {
        vm.startBroadcast();
        fundMe = new WarpFund();
        vm.stopBroadcast();
    }
}
