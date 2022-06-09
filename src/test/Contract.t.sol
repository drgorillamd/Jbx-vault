// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../AJSingleVaultTerminalERC20.sol";
import "jbx/system_tests/helpers/TestBaseWorkflow.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IMintable} from "MockERC4626/interfaces/IMintable.sol";
import {MockLinearGainsERC4626} from "MockERC4626/vaults/MockLinearGainsERC4626.sol";
import {MockERC20} from "MockERC4626/MockERC20.sol";

contract ContractTest is TestBaseWorkflow {
    AJSingleVaultTerminalERC20 private _ajSingleVaultTerminalERC20;
    address private _ajERC20Asset;

    //*********************************************************************//
    // ------------------------- internal views -------------------------- //
    //*********************************************************************//

    function ajSingleVaultTerminalERC20()
        internal
        view
        returns (AJSingleVaultTerminalERC20)
    {
        return _ajSingleVaultTerminalERC20;
    }

    function ajERC20Asset() internal view returns (address) {
        return _ajERC20Asset;
    }

    function setUp() public override {
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

    function testPay() public {
        
        // Create the ERC4626 Vault
        MockLinearGainsERC4626 _vault = new MockLinearGainsERC4626(
            ajERC20Asset(),
            IMintable(ajERC20Asset()),
            "yJBX",
            "yJBX",
            1000
        );

        AJSingleVaultTerminalERC20 _terminal = ajSingleVaultTerminalERC20();

        assertTrue(true);
    }
}
