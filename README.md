# Overview

Pixpress is a universal asset swapping services based on blockchain developed by Pixelava's ecosystem.
This repository is the contract code of Pixpress service.

# Private Key

You'll need to setup private key of your wallet to be able to deploy on chain.
Create a `.env` file on root.
Enter below content and save.
Then you should be able to execute commands correctly.

```
PRIVATE_KEY=<YOUR_WALLET_PRIVATE_KEY>
```

# Testing

Run `yarn test` to trigger local build and testing

# Deploy

Run `yarn deploy:testnet` to deploy on Alfajores Testnet
Run `yarn deploy` to deploy on Celo Mainnet

# Verify

Run `yarn verify:testnet` to verify your deployed contract on Alfajores Testnet
Run `yarn verify` to verify your deployed contract on Celo Mainnet

# Contract Address

Mainnet: TBD
Alfajores: 0x135507dB98dB3776A8E652528803edD52875622C
