# GreenLedger Contracts

A tokenized agricultural supply chain DApp. The goal is to track and transfer ownership of farm produce across the value chain—bringing transparency and trust to agriculture using blockchain.

## Vision
Leverage blockchain to create a transparent, auditable, and efficient agricultural supply chain. Tokenization enables real-time tracking, secure ownership transfer, and data-driven insights for all stakeholders.

## Prerequisites
- Node.js (v16 or higher recommended)
- npm (comes with Node.js)

## Getting Started

### 1. Clone the repository
```bash
git clone <repo-url>
cd greenledger-contracts
```

### 2. Install dependencies
```bash
npm install
```

### 3. Install OpenZeppelin Contracts
OpenZeppelin provides secure, audited implementations of token standards and access control. This is a best practice for any production-grade smart contract project.
```bash
npm install @openzeppelin/contracts
```

### 4. Set up environment variables
Create a `.env` file in the project root (never commit this file):
```
PRIVATE_KEY=your_private_key_here
LISK_SEPOLIA_RPC_URL=https://rpc.sepolia.lisk.com
```
You can use `.env.example` as a template.

### 5. Compile contracts
```bash
npx hardhat compile
```

### 6. Run tests
```bash
npx hardhat test
```

### 7. Deploy to Lisk Sepolia testnet
```bash
npx hardhat run scripts/deploy.js --network lisk_sepolia
```

## Project Structure
```
contracts/      # Solidity smart contracts
scripts/        # Deployment and utility scripts
 test/           # Automated tests
.env            # Environment variables (never commit this)
hardhat.config.js # Hardhat configuration
```

## Security Best Practices
- Never commit your `.env` file or private keys
- Use environment variables for all sensitive data
- Write comprehensive tests for all contracts


## Contribution Guidelines
- Follow the existing project structure
- Write and run tests for all new features

## License
[MIT](./LICENSE)
