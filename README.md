# JBX V2 - Vault Proof-of-concept

| Contract                   | Implementation | Description                                                                                              |
|----------------------------|----------------|----------------------------------------------------------------------------------------------------------|
| AJSingleVaultTerminalETH   | ✅              | Implements `AJSingleVaultTerminal` with support for ETH by wrapping it into wETH*.                       |
| AJSingleVaultTerminalERC20 | ✅              | Implements `AJSingleVaultTerminal` with support for ERC20 tokens.                                        |
| AJSingleVaultTerminal      | 🚫             | Implements the `AJPayoutRedemptionTerminal` and contains the abstract logic for managing a single vault. |
| AJPayoutRedemptionTerminal | 🚫             | Adds hooks for AJ where needed, allowing for an abstraction between the AJ and JBX contracts.            |
_&ast; This is needed because the EIP4626 standard only offers support for ERC20 assets_


## Setup
To set up Foundry:

1. Install [Foundry](https://github.com/gakonst/foundry).
2. Install external libraries

```bash
git submodule update --init
```

4. Run tests:

```bash
yarn test
```

5. Debug a function

```bash
forge run --debug src/MyContract.sol --sig "someFunction()"
```

6. Print a gas report

```bash
yarn test:gas
```

7. Update Foundry periodically:

```bash
foundryup
```

Resources:

- [Forge guide](https://onbjerg.github.io/foundry-book/forge)