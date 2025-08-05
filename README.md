# Decentralized Public Procurement and Contract Management System

A comprehensive blockchain-based system for transparent, secure, and efficient government procurement processes built on the Stacks blockchain using Clarity smart contracts.

## System Overview

This system consists of five interconnected smart contracts that manage the entire procurement lifecycle:

### 1. Vendor Qualification Verification Contract (`vendor-qualification.clar`)
- Validates contractor licenses and certifications
- Tracks insurance coverage and expiration dates
- Maintains historical performance records
- Manages vendor registration and status updates

### 2. Bid Submission and Evaluation Contract (`bid-management.clar`)
- Creates transparent bidding processes for government contracts
- Ensures tamper-proof bid submissions with time-locked reveals
- Implements automated evaluation criteria
- Manages bid opening and winner selection

### 3. Contract Milestone Tracking Contract (`milestone-tracking.clar`)
- Monitors project progress against defined milestones
- Automates payment releases upon deliverable completion
- Tracks timeline adherence and performance metrics
- Manages contract modifications and extensions

### 4. Performance Bond Management Contract (`performance-bonds.clar`)
- Tracks contractor performance bonds and guarantees
- Handles bond claims and dispute resolution
- Manages bond releases upon contract completion
- Maintains bond provider information and ratings

### 5. Public Spending Transparency Contract (`spending-transparency.clar`)
- Provides real-time visibility into government expenditures
- Tracks all procurement-related transactions
- Generates public reports and analytics
- Ensures compliance with transparency regulations

## Key Features

### Transparency
- All procurement activities are recorded on-chain
- Public access to spending data and contract performance
- Immutable audit trails for all transactions

### Security
- Multi-signature approvals for critical operations
- Time-locked bid submissions to prevent manipulation
- Cryptographic verification of all documents and certifications

### Efficiency
- Automated milestone payments and bond releases
- Streamlined vendor qualification processes
- Real-time contract monitoring and reporting

### Compliance
- Built-in regulatory compliance checks
- Automated reporting to oversight bodies
- Standardized procurement procedures

## Contract Architecture

### Data Structures
- **Vendors**: Registration, qualifications, performance history
- **Contracts**: Terms, milestones, payments, status
- **Bids**: Submissions, evaluations, rankings
- **Bonds**: Amounts, providers, claims, releases
- **Transactions**: All financial movements and approvals

### Access Control
- **Government Officials**: Contract creation, vendor approval, milestone verification
- **Vendors**: Bid submission, milestone updates, bond management
- **Citizens**: Read-only access to transparency data
- **Auditors**: Full read access for compliance monitoring

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation
\`\`\`bash
git clone <repository-url>
cd procurement-system
npm install
clarinet check
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register a Vendor
\`\`\`clarity
(contract-call? .vendor-qualification register-vendor
"ABC Construction"
"License123"
u1000000
"Insurance456")
\`\`\`

### Create a Procurement Contract
\`\`\`clarity
(contract-call? .bid-management create-procurement
"Road Construction Project"
u5000000
u30)
\`\`\`

### Submit a Bid
\`\`\`clarity
(contract-call? .bid-management submit-bid
u1
u4500000
"Technical proposal hash")
\`\`\`

### Track Milestone Progress
\`\`\`clarity
(contract-call? .milestone-tracking complete-milestone
u1
u1
"Deliverable evidence hash")
\`\`\`

## Security Considerations

- All sensitive operations require multi-signature approval
- Time delays are implemented for critical state changes
- Input validation prevents malicious data injection
- Access controls ensure proper authorization

## Compliance Features

- Automated audit trail generation
- Regulatory reporting capabilities
- Standardized procurement procedures
- Public transparency requirements

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
