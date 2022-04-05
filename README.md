# JBX V2 - Vault Proof-of-concept

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