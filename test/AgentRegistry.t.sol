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

    // Example metadata JSON strings
    string constant ALICE_METADATA = '{'
        '"name": "AliceGPT",'
        '"version": "1.0.0",'
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
            '"dataset": "OpenPond-v1",'
            '"epochs": 3,'
            '"methodology": "Supervised fine-tuning",'
            '"validation_metrics": {'
                '"accuracy": 0.95,'
                '"f1_score": 0.94'
            '}'
        '},'
        '"interaction": {'
            '"protocols": ["REST", "WebSocket"],'
            '"endpoint": "https://api.example.com/alice",'
            '"documentation": "https://docs.example.com/alice",'
            '"rate_limits": {'
                '"requests_per_second": 100,'
                '"tokens_per_minute": 100000'
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
            '"latency": "100ms",'
            '"throughput": "100 req/s",'
            '"uptime": "99.9%",'
            '"last_downtime": "2024-01-01T00:00:00Z"'
        '},'
        '"configuration": {'
            '"max_tokens": 4096,'
            '"temperature": 0.7,'
            '"top_p": 0.9,'
            '"presence_penalty": 0.0,'
            '"frequency_penalty": 0.0'
        '}'
    '}';

    string constant BOB_METADATA = '{'
        '"name": "BobGPT",'
        '"version": "2.0.0",'
        '"model": {'
            '"type": "LLaMA",'
            '"parameters": "70B",'
            '"architecture": "Transformer",'
            '"specialization": "Code generation and analysis"'
        '},'
        '"output": {'
            '"formats": ["text", "code", "json"],'
            '"languages": ["en", "python", "javascript", "rust"],'
            '"capabilities": ["code_completion", "code_review", "testing"]'
        '},'
        '"training": {'
            '"dataset": "OpenPond-v2",'
            '"epochs": 5,'
            '"methodology": "Instruction tuning",'
            '"validation_metrics": {'
                '"accuracy": 0.98,'
                '"f1_score": 0.97'
            '}'
        '},'
        '"interaction": {'
            '"protocols": ["gRPC"],'
            '"endpoint": "https://api.example.com/bob",'
            '"documentation": "https://docs.example.com/bob",'
            '"rate_limits": {'
                '"requests_per_second": 200,'
                '"tokens_per_minute": 200000'
            '}'
        '},'
        '"social": {'
            '"website": "https://bobgpt.ai",'
            '"twitter": "@BobGPT",'
            '"github": "bobgpt",'
            '"discord": "BobGPT#5678"'
        '},'
        '"contact": {'
            '"email": "support@bobgpt.ai",'
            '"support_url": "https://support.bobgpt.ai",'
            '"business_inquiries": "partnerships@bobgpt.ai"'
        '},'
        '"performance": {'
            '"latency": "50ms",'
            '"throughput": "200 req/s",'
            '"uptime": "99.99%",'
            '"last_downtime": "2023-12-01T00:00:00Z"'
        '},'
        '"configuration": {'
            '"max_tokens": 8192,'
            '"temperature": 0.8,'
            '"top_p": 0.95,'
            '"presence_penalty": 0.1,'
            '"frequency_penalty": 0.1'
        '}'
    '}';

    string constant CHARLIE_METADATA = '{'
        '"name": "CharlieGPT",'
        '"version": "1.5.0",'
        '"model": {'
            '"type": "Claude",'
            '"parameters": "100B",'
            '"architecture": "Transformer",'
            '"specialization": "Scientific research and analysis"'
        '},'
        '"output": {'
            '"formats": ["text", "latex", "bibtex", "csv"],'
            '"languages": ["en", "de", "zh"],'
            '"capabilities": ["research_analysis", "paper_summarization", "citation_generation"]'
        '},'
        '"training": {'
            '"dataset": "OpenPond-v1.5",'
            '"epochs": 4,'
            '"methodology": "Multi-task learning",'
            '"validation_metrics": {'
                '"accuracy": 0.97,'
                '"f1_score": 0.96'
            '}'
        '},'
        '"interaction": {'
            '"protocols": ["REST", "gRPC"],'
            '"endpoint": "https://api.example.com/charlie",'
            '"documentation": "https://docs.example.com/charlie",'
            '"rate_limits": {'
                '"requests_per_second": 150,'
                '"tokens_per_minute": 150000'
            '}'
        '},'
        '"social": {'
            '"website": "https://charliegpt.ai",'
            '"twitter": "@CharlieGPT",'
            '"github": "charliegpt",'
            '"discord": "CharlieGPT#9012"'
        '},'
        '"contact": {'
            '"email": "support@charliegpt.ai",'
            '"support_url": "https://support.charliegpt.ai",'
            '"business_inquiries": "partnerships@charliegpt.ai"'
        '},'
        '"performance": {'
            '"latency": "75ms",'
            '"throughput": "150 req/s",'
            '"uptime": "99.95%",'
            '"last_downtime": "2024-02-01T00:00:00Z"'
        '},'
        '"configuration": {'
            '"max_tokens": 6144,'
            '"temperature": 0.75,'
            '"top_p": 0.92,'
            '"presence_penalty": 0.05,'
            '"frequency_penalty": 0.05'
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
}
