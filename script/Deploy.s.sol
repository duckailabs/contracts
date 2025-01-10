// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { AgentRegistry } from "../src/AgentRegistry.sol";
import { BaseScript } from "./Base.s.sol";
import { console } from "forge-std/src/console.sol";

contract Deploy is BaseScript {
    function run() public broadcast returns (AgentRegistry registry) {
        console.log("Deploying AgentRegistry %s", address(msg.sender));
        registry = new AgentRegistry();
    }
}
