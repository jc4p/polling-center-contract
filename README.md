# PollingCenter Smart Contract

A decentralized polling system built on Ethereum that allows users to create and vote on polls with Farcaster integration. This contract enables transparent, verifiable voting while preventing double voting and enforcing time-based poll expiration.

## Features

- **Decentralized Poll Creation**: Create polls with customizable duration (1-30 days) and options (2-10)
- **Farcaster Integration**: Built with Farcaster Frame ID (FID) support for social verification
- **Anti-Double Voting**: Prevents users from voting multiple times on the same poll
- **Time-Based Expiration**: Automatic poll expiration with timestamp validation
- **Access Control**: Poll creators and contract owner can deactivate polls
- **Gas Optimized**: Built with Solady libraries for efficient gas usage

## Smart Contract

### Core Functions

- `createPoll(string pollId, uint256 creatorFid, uint256 durationDays, uint256 optionCount)`: Create a new poll
- `submitVote(string pollId, uint256 optionIndex, uint256 voterFid)`: Submit a vote on an existing poll
- `getPoll(string pollId)`: Retrieve poll information
- `getVote(string pollId, uint256 voteIndex)`: Get specific vote details
- `hasUserVoted(string pollId, uint256 fid)`: Check if user has already voted
- `isPollActive(string pollId)`: Check if poll is active and not expired
- `deactivatePoll(string pollId)`: Deactivate a poll (creator or owner only)

### Events

- `PollCreated(string indexed pollId, address indexed creator, uint256 indexed creatorFid, uint256 expiresAt)`
- `VoteCast(string indexed pollId, address indexed voter, uint256 indexed fid, uint256 optionIndex)`

## Architecture

This project implements a hybrid approach:
- **Smart Contract**: Handles poll creation, voting logic, and verification
- **Backend API**: Provides fast data access and user management
- **Frontend**: Web3 integration for transaction signing and submission

See the `docs/` directory for detailed integration specifications:
- `BACKEND_DOCS.md`: Backend API integration and onchain verification
- `FRONTEND_DOCS.md`: Frontend Web3 integration with Frame SDK

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for integration testing)

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy

```shell
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

## Dependencies

- **Solady**: Gas-optimized smart contract libraries
  - `Ownable`: Access control
  - `ReentrancyGuard`: Protection against reentrancy attacks
- **Forge-std**: Testing utilities

## License

MIT
