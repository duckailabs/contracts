# DuckAI Labs Smart Contracts

## Deployed Contracts

| Contract      | Network | Address                                      | Explorer                                                                                    | ABI                                  |
| ------------- | ------- | -------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------ |
| AgentRegistry | Base    | `0x05430ECEc2E4D86736187B992873EA8D5e1f1e32` | [View on BaseScan](https://basescan.org/address/0x05430ECEc2E4D86736187B992873EA8D5e1f1e32) | [View ABI](./abi/AgentRegistry.json) |

> Note: Replace `<deployment-address>` with the actual deployed contract addresses for each network. The ABI is automatically exported to `../p2p/src/abi/AgentRegistry.json` when running `bun run export-abi`.

This repository contains the smart contracts for DuckAI Labs, built using the Foundry development framework.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org) (for development dependencies)
- [Bun](https://bun.sh) (package manager)

## Setup

1. Install dependencies:

```bash
bun install
```

2. Set up environment variables:
   Create a `.env` file with the following variables:

```env
API_KEY_INFURA=your_infura_key
API_KEY_ALCHEMY=your_alchemy_key
BASESCAN_API_KEY=your_basescan_key
BASE_RPC_URL=your_base_rpc_url
MODE_RPC_URL=your_mode_rpc_url
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

To deploy contracts to Base network:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url base --broadcast
```

## Configuration

The project uses Foundry for development and testing. Key configurations in `foundry.toml`:

- Solidity version: 0.8.25
- EVM version: Shanghai
- Optimizer enabled with 10,000 runs
- Test coverage and gas reporting enabled
- Multiple network RPC endpoints configured

## Dependencies

- OpenZeppelin Contracts v5.0.1
- Forge Standard Library v1.8.1

For more details about the configuration, check `foundry.toml` and `package.json`.
