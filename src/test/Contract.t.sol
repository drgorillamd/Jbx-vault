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

    JBController controller;
    JBProjectMetadata _projectMetadata;
    JBFundingCycleData _data;
    JBFundingCycleMetadata _metadata;
    JBGroupedSplits[] _groupedSplits; // Default empty
    JBFundAccessConstraints[] _fundAccessConstraints; // Default empty

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

        controller = jbController();

        _projectMetadata = JBProjectMetadata({
            content: "myIPFSHash",
            domain: 1
        });

        _data = JBFundingCycleData({
            duration: 14,
            weight: 1000 * 10**18,
            discountRate: 450000000,
            ballot: IJBFundingCycleBallot(address(0))
        });

        _metadata = JBFundingCycleMetadata({
            global: JBGlobalFundingCycleMetadata({
                allowSetTerminals: false,
                allowSetController: false
            }),
            reservedRate: 5000, //50%
            redemptionRate: 5000, //50%
            ballotRedemptionRate: 0,
            pausePay: false,
            pauseDistributions: false,
            pauseRedeem: false,
            pauseBurn: false,
            allowMinting: false,
            allowChangeToken: false,
            allowTerminalMigration: false,
            allowControllerMigration: false,
            holdFees: false,
            useTotalOverflowForRedemptions: false,
            useDataSourceForPay: false,
            useDataSourceForRedeem: false,
            dataSource: address(0)
        });
    }

    function testPayRedeem() public {
        AJSingleVaultTerminalERC20 _ajERC20Terminal = ajSingleVaultTerminalERC20();

        IJBPaymentTerminal[] memory _terminals = new IJBPaymentTerminal[](1);
        _terminals[0] = _ajERC20Terminal;

        // Configure project
        uint256 projectId = controller.launchProjectFor(
            msg.sender,
            _projectMetadata,
            _data,
            _metadata,
            block.timestamp,
            _groupedSplits,
            _fundAccessConstraints,
            _terminals,
            ""
        );

        // Create the ERC4626 Vault
        MockLinearGainsERC4626 vault = new MockLinearGainsERC4626(
            ajERC20Asset(),
            IMintable(ajERC20Asset()),
            "yJBX",
            "yJBX",
            1000
        );

        // Configure the AJ terminal to use the MockERC4626
        evm.prank(msg.sender);
        _ajERC20Terminal.setVault(
            projectId,
            IERC4626(address(vault)),
            VaultConfig(100_000),
            0
        );

        // Mint some tokens the payer can use
        address payer = address(0xf00);
        uint256 payerAmount = 1 ether;
        IMintable(ajERC20Asset()).mint(payer, payerAmount);

        // Approve the tokens to be paid
        evm.startPrank(payer);
        IERC20(ajERC20Asset()).approve(address(_ajERC20Terminal), payerAmount);

        //emit log_int(_ajERC20Terminal.targetLocalBalanceDelta(projectId, int256(payerAmount)));
        emit log_int(int256(IERC20(_ajERC20Asset).balanceOf(address(_ajERC20Terminal))));

        // Perform the pay
        uint256 jbTokensReceived = _ajERC20Terminal.pay(
            projectId,
            payerAmount,
            ajERC20Asset(),
            payer,
            0,
            false,
            '',
            ''
        );

        emit log_int(int256(IERC20(_ajERC20Asset).balanceOf(address(_ajERC20Terminal))));
        emit log_int(int256(_ajERC20Terminal.currentEthOverflowOf(projectId)));
        emit log_int(_ajERC20Terminal.targetLocalBalanceDelta(projectId, 0));

        // Perform the redeem
        _ajERC20Terminal.redeemTokensOf(payer, projectId, jbTokensReceived, address(jbToken()), 0, payable(payer), '', '');

        emit log_int(int256(IERC20(_ajERC20Asset).balanceOf(address(_ajERC20Terminal))));
        emit log_int(int256(_ajERC20Terminal.currentEthOverflowOf(projectId)));
        emit log_int(_ajERC20Terminal.targetLocalBalanceDelta(projectId, 0));

        evm.stopPrank();
        

        assertTrue(true);
    }
}
