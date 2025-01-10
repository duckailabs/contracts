// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { AgentRegistry } from "../src/AgentRegistry.sol";

contract AgentRegistryTest is Test {
    AgentRegistry public registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address admin = address(this); // Test contract is the admin

    function setUp() public {
        registry = new AgentRegistry();
    }

    function test_RegisterAgent() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(agent.name, "Alice");
        assertEq(agent.metadata, "metadata_uri");
        assertEq(agent.reputation, 100);
        assertTrue(agent.isActive);
        assertFalse(agent.isBlocked);
        vm.stopPrank();
    }

    function test_BlockAgent() public {
        // Register agent
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        // Admin blocks agent
        registry.blockAgent(alice);

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertTrue(agent.isBlocked);
    }

    function test_RevertWhenNonAdminBlocks() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        vm.prank(bob);
        vm.expectRevert(AgentRegistry.NotAdmin.selector);
        registry.blockAgent(alice);
    }

    function test_BlockedAgentCannotInteract() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        vm.prank(bob);
        registry.registerAgent("Bob", "metadata_uri");

        // Admin blocks alice
        registry.blockAgent(alice);

        // Alice tries to interact
        vm.prank(alice);
        vm.expectRevert("Agent not registered or blocked");
        registry.reportInteraction(bob, true);
    }

    function test_UnblockAgent() public {
        // Register and block agent
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        registry.blockAgent(alice);

        // Admin unblocks agent
        registry.unblockAgent(alice);

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertFalse(agent.isBlocked);
    }

    function test_RevertWhenRegisteringTwice() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        vm.expectRevert(AgentRegistry.AgentAlreadyRegistered.selector);
        registry.registerAgent("Alice2", "metadata_uri2");
        vm.stopPrank();
    }

    function test_ReportPositiveInteraction() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        vm.prank(bob);
        registry.registerAgent("Bob", "metadata_uri");

        // Alice reports positive interaction with Bob
        vm.prank(alice);
        registry.reportInteraction(bob, true);

        // Check Bob's reputation increased
        assertEq(registry.getReputation(bob), 101);
        assertEq(registry.positiveInteractions(bob), 1);
        assertEq(registry.totalInteractions(bob), 1);
    }

    function test_RevertWhenReportingTwice() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        vm.prank(bob);
        registry.registerAgent("Bob", "metadata_uri");

        // First report
        vm.prank(alice);
        registry.reportInteraction(bob, true);

        // Second report should fail
        vm.expectRevert(AgentRegistry.AlreadyReportedInteraction.selector);
        vm.prank(alice);
        registry.reportInteraction(bob, true);
    }

    function test_DeactivateAgent() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        registry.deactivateAgent();

        assertFalse(registry.isRegistered(alice));
        vm.stopPrank();
    }

    function test_RevertWhenUnregisteredReports() public {
        vm.prank(bob);
        registry.registerAgent("Bob", "metadata_uri");

        vm.expectRevert("Agent not registered or blocked");
        vm.prank(alice); // alice is not registered
        registry.reportInteraction(bob, true);
    }
}
