// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { AgentRegistry } from "../src/AgentRegistry.sol";
import { Ownable } from "solady/src/auth/Ownable.sol";

contract AgentRegistryTest is Test {
    AgentRegistry public registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address admin = address(this); // Test contract is the admin

    event AgentNameUpdated(
        address indexed agentAddress,
        string name
    );

    // Example metadata JSON strings
    string constant ALICE_METADATA = '{'
        '"capabilities": {'
            '"description": "A general-purpose AI assistant focused on creative and analytical tasks. Excels at natural language understanding, problem-solving, and generating human-like text responses. Can handle complex dialogues while maintaining context and personality.",'
            '"primary_strengths": "Natural language processing, contextual understanding, and creative writing. Particularly strong in maintaining long-term memory and handling multi-turn conversations.",'
            '"specialized_domains": "Content creation, data analysis, and educational assistance. Can generate and explain complex topics in simple terms.",'
            '"limitations": "Cannot access real-time data or external systems. Limited to text-based interactions and pre-trained knowledge cutoff date."'
        '}'
    '}';

    string constant BOB_METADATA = '{'
        '"capabilities": {'
            '"description": "A specialized coding and development AI assistant with deep technical expertise. Focuses on software development, code analysis, and technical documentation. Maintains high accuracy in technical contexts.",'
            '"primary_strengths": "Code generation, debugging, and software architecture design. Excellent at explaining technical concepts and providing detailed documentation.",'
            '"specialized_domains": "Software development, system design, and technical problem-solving. Particularly strong in modern programming languages and best practices.",'
            '"limitations": "Focused primarily on technical tasks. May not perform as well in creative or non-technical contexts."'
        '}'
    '}';

    string constant CHARLIE_METADATA = '{'
        '"capabilities": {'
            '"description": "A research-focused AI assistant specializing in scientific analysis and academic writing. Excels at processing and analyzing scientific literature and data. Strong emphasis on accuracy and citation.",'
            '"primary_strengths": "Scientific research, academic writing, and data analysis. Particularly effective at synthesizing information from multiple sources.",'
            '"specialized_domains": "Academic research, scientific writing, and statistical analysis. Strong capabilities in formatting citations and technical documentation.",'
            '"limitations": "Specialized for academic and research contexts. May not be optimal for casual conversation or creative tasks."'
        '}'
    '}';

    function setUp() public {
        registry = new AgentRegistry();
    }

    function test_RegisterAgent() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(agent.name, "Alice");
        assertEq(agent.metadata, ALICE_METADATA);
        assertEq(agent.id, 1); // First agent gets ID 1
        assertFalse(agent.isBlocked);
        assertFalse(agent.canRate);
        assertEq(uint(agent.status), uint(AgentRegistry.OperationalStatus.ONLINE));
        assertEq(agent.registrationTime, block.timestamp);
        assertEq(agent.recoveryAddress, address(0));
        vm.stopPrank();
    }

    function test_BlockAgent() public {
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);

        registry.blockAgent(alice);

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertTrue(agent.isBlocked);
    }

    function test_RevertWhenNonAdminBlocks() public {
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);

        vm.prank(bob);
        vm.expectRevert(Ownable.Unauthorized.selector);
        registry.blockAgent(alice);
    }

    function test_SetAndRemoveRecoveryAddress() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        registry.setRecoveryAddress(bob);
        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(agent.recoveryAddress, bob);

        registry.removeRecoveryAddress();
        agent = registry.getAgentInfo(alice);
        assertEq(agent.recoveryAddress, address(0));
        vm.stopPrank();
    }

    function test_TransferAgent() public {
        // Register Alice's agent
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        // Set Bob as recovery address
        vm.prank(alice);
        registry.setRecoveryAddress(bob);

        // Transfer from Alice to Charlie (by Alice)
        vm.prank(alice);
        registry.transferAgent(alice, charlie);

        // Verify transfer
        AgentRegistry.Agent memory agent = registry.getAgentInfo(charlie);
        assertEq(agent.name, "Alice");
        assertEq(agent.metadata, ALICE_METADATA);
        
        // Original owner should have no agent
        AgentRegistry.Agent memory emptyAgent = registry.getAgentInfo(alice);
        assertEq(emptyAgent.registrationTime, 0);
    }

    function test_TransferAgentByRecoveryAddress() public {
        // Register and set recovery
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(alice);
        registry.setRecoveryAddress(bob);

        // Transfer by recovery address
        vm.prank(bob);
        registry.transferAgent(alice, charlie);

        // Verify transfer
        AgentRegistry.Agent memory agent = registry.getAgentInfo(charlie);
        assertEq(agent.name, "Alice");
    }

    function test_UpdateOperationalStatus() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.OFFLINE);
        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(uint(agent.status), uint(AgentRegistry.OperationalStatus.OFFLINE));

        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.DISCONTINUED);
        agent = registry.getAgentInfo(alice);
        assertEq(uint(agent.status), uint(AgentRegistry.OperationalStatus.DISCONTINUED));
        vm.stopPrank();
    }

    function test_ReportInteractionWithPermissions() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);

        // Give Alice rating permissions
        registry.setCanRate(alice, true);

        // Alice reports interaction with Bob
        vm.prank(alice);
        registry.reportInteraction(bob, true);

        assertEq(registry.successfulResponses(bob), 1);
        assertEq(registry.totalChecks(bob), 1);
    }

    function test_RevertWhenReportingWithoutPermission() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);

        // Alice tries to report without permission
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.NotAuthorized.selector);
        registry.reportInteraction(bob, true);
    }

    function test_UpdateMetadata() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        // Update to a new version with different configuration
        string memory updatedMetadata = '{'
            '"name": "AliceGPT",'
            '"version": "1.1.0",'  // Version bump
            '"model": {'
                '"type": "GPT-4",'
                '"parameters": "175B",'
                '"architecture": "Transformer",'
                '"specialization": "General purpose language model"'
            '},'
            '"output": {'
                '"formats": ["text", "json", "markdown"],'
                '"languages": ["en", "es", "fr"],'
                '"capabilities": ["chat", "completion", "summarization"]'
            '},'
            '"training": {'
                '"dataset": "OpenPond-v1.1",'  // Updated dataset
                '"epochs": 4,'  // More training
                '"methodology": "Supervised fine-tuning",'
                '"validation_metrics": {'
                    '"accuracy": 0.96,'
                    '"f1_score": 0.95'
                '}'
            '},'
            '"interaction": {'
                '"protocols": ["REST", "WebSocket", "gRPC"],'  // Added gRPC support
                '"endpoint": "https://api.example.com/alice",'
                '"documentation": "https://docs.example.com/alice",'
                '"rate_limits": {'
                    '"requests_per_second": 120,'
                    '"tokens_per_minute": 120000'
                '}'
            '},'
            '"social": {'
                '"website": "https://alicegpt.ai",'
                '"twitter": "@AliceGPT",'
                '"github": "alicegpt",'
                '"discord": "AliceGPT#1234"'
            '},'
            '"contact": {'
                '"email": "support@alicegpt.ai",'
                '"support_url": "https://support.alicegpt.ai",'
                '"business_inquiries": "partnerships@alicegpt.ai"'
            '},'
            '"performance": {'
                '"latency": "90ms",'  // Improved latency
                '"throughput": "120 req/s",'  // Improved throughput
                '"uptime": "99.9%",'
                '"last_downtime": "2024-01-01T00:00:00Z"'
            '},'
            '"configuration": {'
                '"max_tokens": 4096,'
                '"temperature": 0.65,'  // Adjusted for better precision
                '"top_p": 0.92,'  // Adjusted for better precision
                '"presence_penalty": 0.0,'
                '"frequency_penalty": 0.0'
            '}'
        '}';
        
        registry.updateMetadata(updatedMetadata);
        
        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(agent.metadata, updatedMetadata);
        vm.stopPrank();
    }

    function test_RevertWhenDiscontinuedAgentInteracts() public {
        // Register and discontinue
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.DISCONTINUED);
        
        // Try to update metadata
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.updateMetadata(BOB_METADATA);
        vm.stopPrank();
    }

    function test_RevertOnLongName() public {
        string memory longName = new string(201); // Exceeds MAX_NAME_LENGTH
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.registerAgent(longName, ALICE_METADATA);
    }

    function test_RevertOnLongMetadata() public {
        string memory longMetadata = new string(12289); // Exceeds MAX_METADATA_LENGTH
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.registerAgent("Alice", longMetadata);
    }

    function test_RevertOnEmptyName() public {
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.registerAgent("", ALICE_METADATA);
    }

    function test_RevertOnEmptyMetadata() public {
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.registerAgent("Alice", "");
    }

    function test_RevertOnInvalidTransfer() public {
        // Register Alice's agent
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);

        // Try to transfer to zero address
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidTransferTarget.selector);
        registry.transferAgent(alice, address(0));

        // Try to transfer to self
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.InvalidTransferTarget.selector);
        registry.transferAgent(alice, alice);

        // Try to transfer to an address that already has an agent
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.AgentAlreadyRegistered.selector);
        registry.transferAgent(alice, bob);
    }

    function test_TransferHistory() public {
        // Register and do multiple transfers
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        uint256 agentId = registry.getAgentInfo(alice).id;
        
        vm.prank(alice);
        registry.transferAgent(alice, bob);
        
        vm.prank(bob);
        registry.transferAgent(bob, charlie);
        
        // Check transfer history
        AgentRegistry.TransferHistory[] memory history = registry.getTransferHistory(agentId);
        assertEq(history.length, 2);
        assertEq(history[0].previousOwner, alice);
        assertEq(history[1].previousOwner, bob);
    }

    function test_ReportFailedInteraction() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);

        // Give Alice rating permissions
        registry.setCanRate(alice, true);

        // Alice reports failed interaction with Bob
        vm.prank(alice);
        registry.reportInteraction(bob, false);

        assertEq(registry.successfulResponses(bob), 0);
        assertEq(registry.totalChecks(bob), 1);
    }

    function test_UnblockAgent() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        registry.blockAgent(alice);
        registry.unblockAgent(alice);

        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertFalse(agent.isBlocked);
    }

    function test_RevertWhenUnblockingNonBlockedAgent() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        vm.expectRevert(AgentRegistry.AgentNotBlocked.selector);
        registry.unblockAgent(alice);
    }

    function test_RevertWhenSettingInvalidRecoveryAddress() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        vm.expectRevert(AgentRegistry.InvalidRecoveryAddress.selector);
        registry.setRecoveryAddress(address(0));
        
        vm.expectRevert(AgentRegistry.InvalidRecoveryAddress.selector);
        registry.setRecoveryAddress(alice);
        vm.stopPrank();
    }

    function test_RevertWhenRemovingNonexistentRecoveryAddress() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        vm.expectRevert(AgentRegistry.InvalidRecoveryAddress.selector);
        registry.removeRecoveryAddress();
        vm.stopPrank();
    }

    function test_RevertWhenSettingInvalidOperationalStatus() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        // Try to cast an invalid value to OperationalStatus
        uint8 invalidStatus = 3; // Beyond the valid enum range
        vm.expectRevert(AgentRegistry.InvalidOperationalStatus.selector);
        assembly {
            // Direct call to updateOperationalStatus with invalid enum value
            let ptr := mload(0x40)
            mstore(ptr, 0x233e9903) // Function selector for updateOperationalStatus(OperationalStatus)
            mstore(add(ptr, 0x04), invalidStatus)
            let success := call(gas(), sload(registry.slot), 0, ptr, 0x24, 0, 0)
        }
        vm.stopPrank();
    }

    function test_RevertWhenDiscontinuedAgentTriesToChangeStatus() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.DISCONTINUED);
        
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.ONLINE);
        vm.stopPrank();
    }

    function test_SetCanRate() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        // Only admin can set canRate
        registry.setCanRate(alice, true);
        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertTrue(agent.canRate);

        // Admin can also revoke rating permission
        registry.setCanRate(alice, false);
        agent = registry.getAgentInfo(alice);
        assertFalse(agent.canRate);
    }

    function test_RevertWhenNonAdminSetsCanRate() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");

        vm.prank(bob);
        vm.expectRevert(Ownable.Unauthorized.selector);
        registry.setCanRate(alice, true);
    }

    function test_RevertWhenSettingCanRateForNonexistentAgent() public {
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.setCanRate(alice, true);
    }

    function test_RevertWhenSettingCanRateForBlockedAgent() public {
        vm.prank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        
        registry.blockAgent(alice);
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.setCanRate(alice, true);
    }

    function test_RevertWhenSettingCanRateForDiscontinuedAgent() public {
        vm.startPrank(alice);
        registry.registerAgent("Alice", "metadata_uri");
        registry.updateOperationalStatus(AgentRegistry.OperationalStatus.DISCONTINUED);
        vm.stopPrank();

        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.setCanRate(alice, true);
    }

    function test_MultipleAgentsRating() public {
        // Register three agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);
        vm.prank(charlie);
        registry.registerAgent("Charlie", CHARLIE_METADATA);

        // Give rating permissions to Alice and Bob
        registry.setCanRate(alice, true);
        registry.setCanRate(bob, true);

        // Alice and Bob both rate Charlie
        vm.prank(alice);
        registry.reportInteraction(charlie, true); // successful
        vm.prank(bob);
        registry.reportInteraction(charlie, false); // failed

        // Check Charlie's stats
        assertEq(registry.successfulResponses(charlie), 1);
        assertEq(registry.totalChecks(charlie), 2);
    }

    function test_RevertWhenRatingSelf() public {
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        registry.setCanRate(alice, true);

        vm.prank(alice);
        vm.expectRevert(AgentRegistry.NotAuthorized.selector);
        registry.reportInteraction(alice, true);
    }

    function test_RevertWhenRatingBlockedAgent() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);

        // Give Alice rating permission
        registry.setCanRate(alice, true);

        // Block Bob
        registry.blockAgent(bob);

        // Alice tries to rate blocked Bob
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.TargetAgentNotRegistered.selector);
        registry.reportInteraction(bob, true);
    }

    function test_RevertWhenBlockedAgentTrysToRate() public {
        // Register both agents
        vm.prank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        vm.prank(bob);
        registry.registerAgent("Bob", BOB_METADATA);

        // Give Alice rating permission but then block her
        registry.setCanRate(alice, true);
        registry.blockAgent(alice);

        // Blocked Alice tries to rate Bob
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.reportInteraction(bob, true);
    }

    function test_OwnershipInitialization() view public {
        assertEq(registry.owner(), address(this));
    }

    function test_TransferOwnership() public {
        // Alice requests handover first
        vm.prank(alice);
        registry.requestOwnershipHandover();
        
        // Owner completes the handover
        registry.completeOwnershipHandover(alice);
        assertEq(registry.owner(), alice);
    }

    function test_RevertWhenNoHandoverRequest() public {
        // Try to complete handover without request
        vm.expectRevert(Ownable.NoHandoverRequest.selector);
        registry.completeOwnershipHandover(alice);
    }

    function test_CancelOwnershipHandover() public {
        // Alice requests handover
        vm.prank(alice);
        registry.requestOwnershipHandover();
        
        // Alice cancels request
        vm.prank(alice);
        registry.cancelOwnershipHandover();
        
        // Try to complete cancelled handover
        vm.expectRevert(Ownable.NoHandoverRequest.selector);
        registry.completeOwnershipHandover(alice);
    }

    function test_OwnershipHandoverExpiry() public {
        // Alice requests handover
        vm.prank(alice);
        registry.requestOwnershipHandover();
        
        // Warp past handover validity period (48 hours + 1 second)
        vm.warp(block.timestamp + 48 hours + 1);
        
        // Try to complete expired handover
        vm.expectRevert(Ownable.NoHandoverRequest.selector);
        registry.completeOwnershipHandover(alice);
    }

    function test_RenounceOwnership() public {
        registry.renounceOwnership();
        assertEq(registry.owner(), address(0));
        
        // Try to call an owner function after renouncing
        vm.expectRevert(Ownable.Unauthorized.selector);
        registry.blockAgent(alice);
    }

    function test_RevertWhenNonOwnerRenounces() public {
        vm.prank(alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        registry.renounceOwnership();
    }

    function test_RevertWhenTransferringToZeroAddress() public {
        vm.expectRevert(Ownable.NewOwnerIsZeroAddress.selector);
        registry.transferOwnership(address(0));
    }

    function test_UpdateName() public {
        // Register Alice's agent
        vm.startPrank(alice);
        registry.registerAgent("Alice", ALICE_METADATA);
        
        // Update name and verify event emission
        vm.expectEmit(true, false, false, true);
        emit AgentNameUpdated(alice, "AliceV2");
        registry.updateName("AliceV2");

        // Verify name was updated
        AgentRegistry.Agent memory agent = registry.getAgentInfo(alice);
        assertEq(agent.name, "AliceV2");

        // Test name validation
        // Empty name should revert
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.updateName("");

        // Too long name should revert (201 characters)
        string memory tooLongName = "ThisNameIsWayTooLongAndShouldFailBecauseItExceedsTheMaximumAllowedLengthForAnAgentNameInTheRegistryContractWhichIsSetToTwoHundredCharactersThisStringIsDefinitelyLongerThanThatSoItShouldRevertWhenWeAttemptToUpdateTheNameWithIt";
        vm.expectRevert(AgentRegistry.InvalidStringLength.selector);
        registry.updateName(tooLongName);
        vm.stopPrank();

        // Blocked agents cannot update name
        registry.blockAgent(alice);
        vm.prank(alice);
        vm.expectRevert(AgentRegistry.AgentNotRegistered.selector);
        registry.updateName("NewName");
    }
}
