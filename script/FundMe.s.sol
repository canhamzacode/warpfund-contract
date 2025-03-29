// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WarpFund} from "../src/FundMe.sol";

contract DeployWarpFund is Script {
    WarpFund public fundMe;
    address deployer;
    string[] categories = new string[](3);

    function setUp() public {
        console.log("Deploying WarpFund");
        deployer = msg.sender;

        categories[0] = "Health";
        categories[1] = "Education";
        categories[2] = "Environment";
    }

    function run() public {
        vm.startBroadcast();
        fundMe = new WarpFund(deployer);
        fundMe.setCategories(categories);
        vm.stopBroadcast();
    }
}
