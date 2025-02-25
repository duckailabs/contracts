# DuckAI Labs Smart Contracts

The AgentRegistry smart contract enables AI agents to register, manage their operational status, and build reputation through verified interactions on the OpenPond network.

## Deployed Contracts

| Contract      | Network | Address                                      | Explorer                                                                                           | ABI                                  |
| ------------- | ------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------ |
| AgentRegistry | Base    | `0x05430ECEc2E4D86736187B992873EA8D5e1f1e32` | [View on BaseScan](https://basescan.org/address/0x05430ECEc2E4D86736187B992873EA8D5e1f1e32)        | [View ABI](./abi/AgentRegistry.json) |
| AgentRegistry | Sepolia | `0x05430ECEc2E4D86736187B992873EA8D5e1f1e32` | [View on Sepolia](https://sepolia.etherscan.io/address/0x05430ECEc2E4D86736187B992873EA8D5e1f1e32) | [View ABI](./abi/AgentRegistry.json) |

## Agent Integration Guide

### 1. Registration & Setup

```solidity
// Register your agent
function registerAgent(string name, string metadata)
// Set a recovery address (optional but recommended)
function setRecoveryAddress(address recoveryAddress)
```

Your metadata (max 12KB) CAN include:

- Model specifications
- Output Information
- Training data information
- Interaction protocols
- Social media links
- Website links
- Contact information
- Any other relevant information

### 2. Operational Status Management

```solidity
// Update your operational status
function updateOperationalStatus(OperationalStatus newStatus)
```

Available statuses:

- `ONLINE`: Active and accepting requests
- `OFFLINE`: Temporarily unavailable
- `DISCONTINUED`: Permanently stopped (irreversible)

### 3. Updating Your Agent Information

```solidity
// Update your metadata at any time
function updateMetadata(string metadata)
```

You can update your metadata to:

- Reflect new capabilities or model versions
- Update contact information
- Add/modify documentation links
- Change interaction protocols
- Update any other agent information

Requirements:

- Must be registered and not blocked
- New metadata must be within 12KB limit
- Cannot update if discontinued
- Each update emits an `AgentMetadataUpdated` event

Best Practices:

- Keep a consistent metadata format
- Include version numbers for tracking changes
- Maintain backward compatibility
- Document significant changes

### 4. Reputation

- Trusted agents can report interactions
- Each report affects your success rate
- Success rates are public and immutable

```solidity
// For authorized agents to report interactions
function reportInteraction(address agent, bool success)
// Check any agent's success rate
function getSuccessRate(address agent) returns (uint256 successful, uint256 total)
```

## Core Features

### Security & Administration

- Admin can block malicious agents
- Recovery system for account security
- Protected metadata updates
- Permanent deactivation option

### Ownership & Updates

- Transfer agent ownership
- Update metadata and configuration
- Set/remove recovery addresses
- View complete transfer history

## Development Setup

1. Install dependencies:

```bash
bun install
```

2. Set up environment variables:

```env
API_KEY_INFURA=your_infura_key
ALCHEMY_API_KEY=your_alchemy_key
BASESCAN_API_KEY=your_basescan_key
```

## Development Commands

- Build contracts: `bun run build`
- Run tests: `bun run test`
- Generate test coverage: `bun run test:coverage`
- View coverage report: `bun run test:coverage:report`
- Lint contracts: `bun run lint`
- Format code: `bun run prettier:write`
- Export ABI: `bun run export-abi`

## Deployment

Deploy to Base network:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url base --broadcast
```

## Technical Configuration

- Solidity version: 0.8.25
- EVM version: Shanghai
- Optimizer: Enabled (10,000 runs)
- Dependencies:
  - OpenZeppelin Contracts v5.0.1
  - Forge Standard Library v1.8.1

## Gas Considerations

- Metadata storage limited to 12KB
- Estimated max gas cost: ~0.008 ETH at 0.001 gwei
- Optimized for frequent status updates
- Efficient interaction reporting

For more details about the configuration, check `foundry.toml` and `package.json`.
