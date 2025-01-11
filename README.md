# DeFi Indices Model Contracts

This repository contains the smart contracts for the DeFi Indices Model developed by Nex Labs. These contracts enable the creation and management of decentralized financial indices on the blockchain. The project leverages Foundry for testing and development.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

DeFi Indices are a powerful tool for bundling multiple assets into a single, tradable token. This project provides:

- A flexible and modular framework for creating index-based financial products.
- Integration with on-chain data providers and oracles for real-time index value calculation.
- Decentralized and permissionless index management.

## Features

- **Composability**: Easily integrate with other DeFi protocols.
- **Customization**: Define custom index strategies and asset compositions.
- **Transparency**: Fully auditable on-chain processes.
- **Automation**: Rebalancing and index updates through automated bots or smart contract triggers.

## Getting Started

To get started with the project, ensure you have the following prerequisites installed:

- [Foundry](https://book.getfoundry.sh/): A fast, portable, and modular toolkit for Ethereum application development written in Rust.
- [Node.js](https://nodejs.org/) (optional, for auxiliary tools).

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/nexlabs22/Defi-Indices-Model-Contracts.git
   cd Defi-Indices-Model-Contracts
   ```
2. Install dependencies:

   ```bash
   npm install
   forge install
   ```
3. Build the project:

   ```bash
   forge build
   ```

### Usage

Deploy the contracts to your preferred Ethereum-compatible network using Foundry:

1. Update the `.env` file with your RPC URL and private key.
2. Deploy the contracts:

   ```bash
   forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
   ```

### Testing

Run the test suite to ensure everything is functioning correctly:

```bash
forge test
```

You can add the `-vvv` flag for detailed logs:

```bash
forge test -vvv
```

### Directory Structure

- `src/`: Contains the main contract source code.
- `lib/`: Dependencies installed via Foundry.
- `test/`: Contains the test files for the contracts.
- `script/`: Deployment and automation scripts.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix:

   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit your changes and push the branch:

   ```bash
   git commit -m "Add your feature description"
   git push origin feature/your-feature-name
   ```
4. Open a pull request with a detailed description of your changes.

## License

This project is licensed under the [MIT License](LICENSE).
