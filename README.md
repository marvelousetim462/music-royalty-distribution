# Music Royalty Distribution System

## Overview

The Music Royalty Distribution System is an automated blockchain-based platform that enables transparent and efficient distribution of music streaming royalties to artists, producers, and rights holders. Built on the Stacks blockchain using Clarity smart contracts, this system ensures fair compensation through predefined splits and automated contract execution.

## Features

### Core Functionality
- **Automated Royalty Distribution**: Distribute streaming royalties based on predefined percentage splits
- **Multi-Party Settlements**: Support multiple stakeholders (artists, producers, songwriters, labels)
- **Transparent Tracking**: Immutable record of all royalty distributions and payments
- **Flexible Split Configurations**: Customizable royalty splits for different types of rights holders

### Smart Contract Capabilities
- **Royalty Pool Management**: Create and manage royalty pools for individual tracks or albums
- **Stakeholder Registration**: Register rights holders with their respective ownership percentages
- **Automated Payments**: Execute payments automatically when royalties are deposited
- **Dispute Resolution**: Built-in mechanisms for handling payment disputes

## Technical Architecture

### Smart Contracts
- **Royalty Splitter**: Main contract handling royalty distribution logic
- **Stakeholder Management**: Manages rights holder information and split percentages
- **Payment Processing**: Handles STX token transfers and payment confirmations

### Key Components
- **Split Configuration**: Define how royalties should be distributed among stakeholders
- **Payment Queue**: Queue system for processing multiple payments efficiently
- **Audit Trail**: Complete transaction history for transparency and compliance

## Getting Started

### Prerequisites
- Node.js (v16 or higher)
- Clarinet CLI
- Stacks Wallet for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/marvelousetim462/music-royalty-distribution.git
cd music-royalty-distribution
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
clarinet test
```

## Usage

### Setting Up a Royalty Split

1. **Create a New Track Entry**:
   - Register the track with unique identifier
   - Define the total rights holders and their percentages

2. **Configure Payment Rules**:
   - Set minimum payment thresholds
   - Configure payment frequency (immediate or batched)

3. **Deposit Royalties**:
   - Stream platforms deposit royalties to the contract
   - Automatic distribution triggers based on predefined splits

### Example Split Configuration

```clarity
;; Example: 60% to artist, 25% to producer, 15% to songwriter
{
  track-id: "track-001",
  splits: [
    {stakeholder: 'SP1ABC...', percentage: 60},
    {stakeholder: 'SP2DEF...', percentage: 25},
    {stakeholder: 'SP3GHI...', percentage: 15}
  ]
}
```

## Contract Functions

### Core Functions
- `create-royalty-pool`: Initialize a new royalty distribution pool
- `add-stakeholder`: Add rights holder to a track's distribution
- `deposit-royalties`: Deposit streaming royalties for distribution
- `claim-payment`: Allow stakeholders to claim their share
- `update-split`: Modify distribution percentages (requires consensus)

### Administrative Functions
- `set-minimum-payment`: Configure minimum payment thresholds
- `pause-contract`: Emergency pause functionality
- `resolve-dispute`: Handle payment disputes

## Security Features

- **Multi-signature Requirements**: Critical operations require multiple approvals
- **Percentage Validation**: Ensures split percentages always total 100%
- **Access Control**: Role-based permissions for different contract functions
- **Emergency Pause**: Ability to halt operations in case of issues

## Testing

Run the comprehensive test suite:

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Run specific test file
clarinet test tests/royalty-splitter-test.ts
```

## Deployment

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:
- Create an issue in this repository
- Contact the development team
- Check our documentation wiki

## Roadmap

- [ ] Integration with major streaming platforms
- [ ] Mobile app for stakeholder management  
- [ ] Advanced analytics and reporting
- [ ] Cross-chain compatibility
- [ ] Automated tax reporting features

---

Built with ❤️ using Stacks blockchain and Clarity smart contracts.