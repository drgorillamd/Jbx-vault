// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../AJSingleVaultTerminalERC20.sol";
import "jbx/system_tests/helpers/TestBaseWorkflow.sol";

import {ERC4626} from "solmate/mixins/ERC4626.sol";

contract ContractTest is TestBaseWorkflow {
    AJSingleVaultTerminalERC20 private _ajSingleVaultTerminalERC20;

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

    function setUp() public override {
        super.setUp();

        // Deploy AJ ERC20 Terminal
        _ajSingleVaultTerminalERC20 = new AJSingleVaultTerminalERC20(
            jbToken(),
            jbLibraries().ETH(), // currency
            jbLibraries().ETH(), // base weight currency
            1, // JBSplitsGroupe
            jbOperatorStore(),
            jbProjects(),
            jbDirectory(),
            jbSplitsStore(),
            jbPrices(),
            jbPaymentTerminalStore(),
            multisig()
        );
        
        // Label the ERC20 address
        evm.label(address(_ajSingleVaultTerminalERC20), 'AJSingleVaultTerminalERC20');
    }

    function testPay() public {

        // Deploy AJ ERC20 Terminal
        _ajSingleVaultTerminalERC20 = new AJSingleVaultTerminalERC20(
            jbToken(),
            jbLibraries().ETH(), // currency
            jbLibraries().ETH(), // base weight currency
            1, // JBSplitsGroupe
            jbOperatorStore(),
            jbProjects(),
            jbDirectory(),
            jbSplitsStore(),
            jbPrices(),
            jbPaymentTerminalStore(),
            multisig()
        );

        // Create ERC4626 Vault
        ERC4626 _vault = new ERC4626(
            jbToken(),
            "yJBX",
            "yJBX"
        );

        AJSingleVaultTerminalERC20 _terminal = ajSingleVaultTerminalERC20();


        
        assertTrue(true);
    }
}
