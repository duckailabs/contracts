// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract AgentRegistry {
    error NotAdmin();
    error AgentAlreadyBlocked();
    error AgentNotBlocked();
    error AgentAlreadyRegistered();
    error AgentNotRegistered();
    error TargetAgentNotRegistered();
    error AlreadyReportedInteraction();

    struct Agent {
        string name;
        string metadata;
        uint256 reputation;
        bool isActive;
        bool isBlocked;
        uint256 registrationTime;
    }

    address public immutable admin;
    mapping(address agent => Agent info) public agents;
    mapping(address reporter => mapping(address target => bool hasInteracted)) public hasInteracted;
    mapping(address agent => uint256 count) public positiveInteractions;
    mapping(address agent => uint256 count) public totalInteractions;

    event AgentRegistered(address indexed agentAddress, string name, string metadata);
    event ReputationUpdated(address indexed agentAddress, uint256 newReputation);
    event AgentDeactivated(address indexed agentAddress);
    event AgentBlocked(address indexed agentAddress);
    event AgentUnblocked(address indexed agentAddress);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier onlyRegistered() {
        require(agents[msg.sender].isActive && !agents[msg.sender].isBlocked, "Agent not registered or blocked");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function blockAgent(address agent) external onlyAdmin {
        if (agents[agent].isBlocked) revert AgentAlreadyBlocked();
        agents[agent].isBlocked = true;
        emit AgentBlocked(agent);
    }

    function unblockAgent(address agent) external onlyAdmin {
        if (!agents[agent].isBlocked) revert AgentNotBlocked();
        agents[agent].isBlocked = false;
        emit AgentUnblocked(agent);
    }

    function registerAgent(string memory name, string memory metadata) external {
        if (agents[msg.sender].isActive) revert AgentAlreadyRegistered();

        agents[msg.sender] = Agent({
            name: name,
            metadata: metadata,
            reputation: 100, // Starting reputation
            isActive: true,
            isBlocked: false,
            registrationTime: block.timestamp
        });

        emit AgentRegistered(msg.sender, name, metadata);
    }

    function reportInteraction(address agent, bool positive) external onlyRegistered {
        if (!agents[agent].isActive) revert TargetAgentNotRegistered();
        if (hasInteracted[msg.sender][agent]) revert AlreadyReportedInteraction();

        hasInteracted[msg.sender][agent] = true;
        totalInteractions[agent]++;

        if (positive) {
            positiveInteractions[agent]++;
            agents[agent].reputation += 1;
        } else {
            if (agents[agent].reputation > 0) {
                agents[agent].reputation -= 1;
            }
        }

        emit ReputationUpdated(agent, agents[agent].reputation);
    }

    function deactivateAgent() external onlyRegistered {
        agents[msg.sender].isActive = false;
        emit AgentDeactivated(msg.sender);
    }

    function getAgentInfo(address agentAddress) external view returns (Agent memory) {
        return agents[agentAddress];
    }

    function isRegistered(address agentAddress) external view returns (bool) {
        return agents[agentAddress].isActive;
    }

    function getReputation(address agentAddress) external view returns (uint256) {
        return agents[agentAddress].reputation;
    }
}
