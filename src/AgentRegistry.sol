// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "solady/src/auth/Ownable.sol";

contract AgentRegistry is Ownable {
    error AgentAlreadyBlocked();
    error AgentNotBlocked();
    error AgentAlreadyRegistered();
    error AgentNotRegistered();
    error TargetAgentNotRegistered();
    error AlreadyReportedInteraction();
    error InvalidTransferTarget();
    error NotAuthorized();
    error InvalidRecoveryAddress();
    error InvalidStringLength();
    error InvalidAgentId();
    error InvalidOperationalStatus();

    uint256 public constant MAX_NAME_LENGTH = 200;
    // 12KB limit allows for rich AI metadata including:
    // - Model specifications
    // - Capabilities
    // - Training data information
    // - Social media links
    // - Configuration JSON
    uint256 public constant MAX_METADATA_LENGTH = 12288; // 12KB

    enum OperationalStatus {
        ONLINE,     // Agent is running and accepting requests
        OFFLINE,    // Agent is temporarily down (maintenance etc)
        DISCONTINUED // Agent has permanently stopped service
    }

    struct Agent {
        uint256 id;
        string name;
        string metadata;
        bool isBlocked;
        bool canRate;        
        OperationalStatus status;
        uint256 registrationTime;
        address recoveryAddress;
    }

    struct TransferHistory {
        address previousOwner;
        uint256 transferTime;
    }

    uint256 private nextAgentId = 1;
    mapping(address agent => Agent info) public agents;
    mapping(address agent => uint256) public successfulResponses;
    mapping(address agent => uint256) public totalChecks;
    mapping(uint256 agentId => TransferHistory[]) public transferHistory;
    mapping(uint256 agentId => address) private agentById;

    event AgentRegistered(address indexed agentAddress, string name, string metadata);
    event AgentDeactivated(address indexed agentAddress);
    event AgentBlocked(address indexed agentAddress);
    event AgentUnblocked(address indexed agentAddress);
    event AgentResponseRecorded(
        address indexed agentAddress,
        bool success,
        uint256 totalSuccessful,
        uint256 totalChecks
    );
    event AgentTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 indexed agentId,
        uint256 timestamp
    );
    event RecoveryAddressSet(
        address indexed agentAddress,
        address indexed recoveryAddress
    );
    event AgentMetadataUpdated(
        address indexed agentAddress,
        string metadata
    );
    event OperationalStatusUpdated(
        address indexed agentAddress,
        OperationalStatus status
    );
    event AgentNameUpdated(
        address indexed agentAddress,
        string name
    );

    modifier onlyRegistered() {
        if (agents[msg.sender].isBlocked || agents[msg.sender].status == OperationalStatus.DISCONTINUED) {
            revert AgentNotRegistered();
        }
        _;
    }

    modifier validateName(string memory str) {
        if (bytes(str).length > MAX_NAME_LENGTH) revert InvalidStringLength();
        if (bytes(str).length == 0) revert InvalidStringLength();
        _;
    }

    modifier validateMetadata(string memory str) {
        if (bytes(str).length > MAX_METADATA_LENGTH) revert InvalidStringLength();
        if (bytes(str).length == 0) revert InvalidStringLength();
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function blockAgent(address agent) external onlyOwner {
        if (agents[agent].isBlocked) revert AgentAlreadyBlocked();
        agents[agent].isBlocked = true;
        emit AgentBlocked(agent);
    }

    function unblockAgent(address agent) external onlyOwner {
        if (!agents[agent].isBlocked) revert AgentNotBlocked();
        agents[agent].isBlocked = false;
        emit AgentUnblocked(agent);
    }

    function registerAgent(string memory name, string memory metadata) 
        external 
        validateName(name)
        validateMetadata(metadata)
    {
        if (agents[msg.sender].registrationTime != 0) revert AgentAlreadyRegistered();

        uint256 agentId = nextAgentId++;
        agents[msg.sender] = Agent({
            id: agentId,
            name: name,
            metadata: metadata,
            isBlocked: false,
            canRate: false,
            status: OperationalStatus.ONLINE,
            registrationTime: block.timestamp,
            recoveryAddress: address(0)
        });

        agentById[agentId] = msg.sender;
        emit AgentRegistered(msg.sender, name, metadata);
    }

    function setRecoveryAddress(address recoveryAddress) external onlyRegistered {
        if (recoveryAddress == address(0) || recoveryAddress == msg.sender) {
            revert InvalidRecoveryAddress();
        }
        
        agents[msg.sender].recoveryAddress = recoveryAddress;
        emit RecoveryAddressSet(msg.sender, recoveryAddress);
    }

    function removeRecoveryAddress() external onlyRegistered {
        if (agents[msg.sender].recoveryAddress == address(0)) {
            revert InvalidRecoveryAddress();
        }
        
        agents[msg.sender].recoveryAddress = address(0);
        emit RecoveryAddressSet(msg.sender, address(0));
    }

    function transferAgent(address owner, address newOwner) external {
        Agent storage agent = agents[owner];
        if (agent.registrationTime == 0) revert AgentNotRegistered();
        if (agent.isBlocked) revert AgentAlreadyBlocked();
        if (agent.status == OperationalStatus.DISCONTINUED) revert AgentNotRegistered();
        
        // Either owner or recovery address can transfer
        if (msg.sender != owner && msg.sender != agent.recoveryAddress) {
            revert NotAuthorized();
        }

        // Basic checks
        if (newOwner == address(0) || newOwner == owner) revert InvalidTransferTarget();
        if (agents[newOwner].registrationTime != 0) revert AgentAlreadyRegistered();

        // Execute transfer
        transferHistory[agent.id].push(TransferHistory({
            previousOwner: owner,
            transferTime: block.timestamp
        }));

        Agent memory currentAgent = agent;
        delete agents[owner];
        agents[newOwner] = currentAgent;
        agentById[currentAgent.id] = newOwner;

        emit AgentTransferred(owner, newOwner, currentAgent.id, block.timestamp);
    }

    function reportInteraction(address agent, bool success) external {
        if (agents[msg.sender].status == OperationalStatus.DISCONTINUED) revert AgentNotRegistered();
        if (agents[msg.sender].isBlocked) revert AgentNotRegistered();
        if (!agents[msg.sender].canRate) revert NotAuthorized();
        if (agents[agent].status == OperationalStatus.DISCONTINUED) revert TargetAgentNotRegistered();
        if (agents[agent].isBlocked) revert TargetAgentNotRegistered();
        if (msg.sender == agent) revert NotAuthorized();

        totalChecks[agent]++;
        if (success) {
            successfulResponses[agent]++;
        }

        emit AgentResponseRecorded(agent, success, successfulResponses[agent], totalChecks[agent]);
    }

    function updateOperationalStatus(OperationalStatus newStatus) external onlyRegistered {
        if (uint8(newStatus) > uint8(OperationalStatus.DISCONTINUED)) revert InvalidOperationalStatus();
        // Once discontinued, cannot change status
        if (agents[msg.sender].status == OperationalStatus.DISCONTINUED) revert AgentNotRegistered();
        
        agents[msg.sender].status = newStatus;
        emit OperationalStatusUpdated(msg.sender, newStatus);
        
        if (newStatus == OperationalStatus.DISCONTINUED) {
            emit AgentDeactivated(msg.sender);
        }
    }

    function setCanRate(address agent, bool canRate) external onlyOwner {
        if (agents[agent].registrationTime == 0) revert AgentNotRegistered();
        if (agents[agent].isBlocked) revert AgentNotRegistered();
        if (agents[agent].status == OperationalStatus.DISCONTINUED) revert AgentNotRegistered();
        agents[agent].canRate = canRate;
    }

    function updateMetadata(string memory metadata) 
        external 
        validateMetadata(metadata) 
        onlyRegistered 
    {
        agents[msg.sender].metadata = metadata;
        emit AgentMetadataUpdated(msg.sender, metadata);
    }

    function updateName(string memory name)
        external
        validateName(name)
        onlyRegistered
    {
        agents[msg.sender].name = name;
        emit AgentNameUpdated(msg.sender, name);
    }

    // View functions
    function getAgentInfo(address agentAddress) external view returns (Agent memory) {
        return agents[agentAddress];
    }

    function isRegistered(address agentAddress) external view returns (bool) {
        Agent memory agent = agents[agentAddress];
        return agent.registrationTime != 0 && 
               !agent.isBlocked && 
               agent.status != OperationalStatus.DISCONTINUED;
    }

    function getSuccessRate(address agentAddress) external view returns (uint256 successful, uint256 total) {
        return (successfulResponses[agentAddress], totalChecks[agentAddress]);
    }

    function getTotalAgents() external view returns (uint256) {
        return nextAgentId - 1;
    }

    function getAgentById(uint256 agentId) external view returns (address) {
        address agentAddr = agentById[agentId];
        if (agentAddr == address(0)) revert InvalidAgentId();
        return agentAddr;
    }

    function getTransferHistory(uint256 agentId) external view returns (TransferHistory[] memory) {
        if (agentById[agentId] == address(0)) revert InvalidAgentId();
        return transferHistory[agentId];
    }
}
