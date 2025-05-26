// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {PollingCenter} from "../src/PollingCenter.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        PollingCenter pollingCenter = new PollingCenter();

        console2.log("PollingCenter deployed to:", address(pollingCenter));

        vm.stopBroadcast();
    }
}