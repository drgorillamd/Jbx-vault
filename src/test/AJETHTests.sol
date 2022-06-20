// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./abstract/AJPayoutRedemptionTerminalTests.sol";
import {MockERC20} from "MockERC4626/MockERC20.sol";

// TODO: Abstract for now since we don't have the full testing setup ready for ETH terminals
abstract contract AJETHTests is AJPayoutRedemptionTerminalTests {
    AJSingleVaultTerminalERC20 private _ajSingleVaultTerminalERC20;
    address private _ajERC20Asset;

    //*********************************************************************//
    // ---------------------------  overrides ---------------------------- //
    //*********************************************************************//

    function AJPayoutRedemptionTerminal()
    internal
    view
    virtual
    override
    returns (IJBPayoutRedemptionPaymentTerminal terminal){
        terminal = IJBPayoutRedemptionPaymentTerminal(_ajSingleVaultTerminalERC20);
    }

    function ajAsset() internal virtual override view returns (address) {
        return _ajERC20Asset;
    }

    function ajAssetBalanceOf(address addr) internal virtual override view returns (uint256){
        return payable(addr).balance;
    }

    function fundWallet(address addr, uint256 amount) internal virtual override {
        evm.deal(addr, payable(addr).balance + amount);
    }

    function beforeTransfer(address from, address to, uint256 amount) internal virtual override returns (uint256) {
        return amount;
    }

    //*********************************************************************//
    // ------------------------- virtual methods ------------------------- //
    //*********************************************************************//

    function setUp() public override {
        // Setup Juicebox
        super.setUp();

        // Create the valuable asset
        _ajERC20Asset = address(new MockERC20("MockAsset", "MAsset", 18));
        evm.label(_ajERC20Asset, "MockAsset");

        // Deploy AJ ERC20 Terminal
        _ajSingleVaultTerminalERC20 = new AJSingleVaultTerminalERC20(
            IERC20Metadata(_ajERC20Asset),
            jbLibraries().ETH(), // currency
            jbLibraries().ETH(), // base weight currency
            1, // JBSplitsGroup
            jbOperatorStore(),
            jbProjects(),
            jbDirectory(),
            jbSplitsStore(),
            jbPrices(),
            jbPaymentTerminalStore(),
            multisig()
        );

        // Label the ERC20 address
        evm.label(
            address(_ajSingleVaultTerminalERC20),
            "AJSingleVaultTerminalERC20"
        );
    }
}