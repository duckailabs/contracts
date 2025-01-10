// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $PRIVATE_KEY environment variable.
    uint256 internal constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /// @dev Depends on the environment variable $PRIVATE_KEY.
    uint256 internal privateKey;

    constructor() {
        privateKey = vm.envOr("PRIVATE_KEY", DEFAULT_ANVIL_KEY);
    }

    modifier broadcast() {
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }
}
