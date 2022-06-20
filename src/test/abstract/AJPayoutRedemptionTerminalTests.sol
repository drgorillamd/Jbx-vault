// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../../AJSingleVaultTerminalERC20.sol";
import "jbx/system_tests/helpers/TestBaseWorkflow.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IMintable} from "MockERC4626/interfaces/IMintable.sol";
import {MockLinearGainsERC4626} from "MockERC4626/vaults/MockLinearGainsERC4626.sol";
import {MockERC20} from "MockERC4626/MockERC20.sol";

abstract contract AJPayoutRedemptionTerminalTests is TestBaseWorkflow {
    JBController controller;
    JBProjectMetadata _projectMetadata;
    JBFundingCycleData _data;
    JBFundingCycleMetadata _metadata;
    JBGroupedSplits[] _groupedSplits; // Default empty
    JBFundAccessConstraints[] _fundAccessConstraints; // Default empty

    //*********************************************************************//
    // ------------------------- virtual methods ------------------------- //
    //*********************************************************************//

    function AJPayoutRedemptionTerminal()
    internal
    virtual
    view
    returns (IJBPayoutRedemptionPaymentTerminal terminal);

    function ajAsset() internal virtual view returns (address);

    function ajAssetBalanceOf(address addr) internal virtual view returns (uint256);

    function fundWallet(address addr, uint256 amount) internal virtual;

    function beforeTransfer(address from, address to, uint256 amount) internal virtual returns (uint256 value);

    //*********************************************************************//
    // ------------------------- internal views -------------------------- //
    //*********************************************************************//

    function setUp() public virtual override {
        super.setUp();

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

    function testPayRedeemFuzz(uint40 _LocalBalancePPM, uint128 _payAmount) public {
        uint256 _localBalancePPMNormalised = _LocalBalancePPM / 1_000_000;
        evm.assume(_localBalancePPMNormalised > 0 && _localBalancePPMNormalised < 1_000_000);
        evm.assume(_payAmount > 0);

        AJSingleVaultTerminalERC20 _ajERC20Terminal = AJSingleVaultTerminalERC20(address(AJPayoutRedemptionTerminal()));

        IJBPaymentTerminal[] memory _terminals = new IJBPaymentTerminal[](1);
        _terminals[0] = AJPayoutRedemptionTerminal();

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
            ajAsset(),
            IMintable(ajAsset()),
            "yJBX",
            "yJBX",
            1000
        );

        // Configure the AJ terminal to use the MockERC4626
        evm.prank(msg.sender);
        _ajERC20Terminal.setVault(
            projectId,
            IERC4626(address(vault)),
            VaultConfig(_localBalancePPMNormalised),
            0
        );

        // Mint some tokens the payer can use
        address payer = address(0xf00);

        fundWallet(payer, _payAmount);
        beforeTransfer(payer, address(_ajERC20Terminal), _payAmount);

        // Approve the tokens to be paid
        evm.startPrank(payer);

        // Perform the pay
        uint256 jbTokensReceived = _ajERC20Terminal.pay(
            projectId,
            _payAmount,
            ajAsset(),
            payer,
            0,
            false,
            '',
            ''
        );

        assertEq(_ajERC20Terminal.targetLocalBalanceDelta(projectId, 0), 0);
        emit log_named_uint("Local balance after deposit", ajAssetBalanceOf(address(_ajERC20Terminal)));

        // Perform the redeem
        _ajERC20Terminal.redeemTokensOf(payer, projectId, jbTokensReceived, address(jbToken()), 0, payable(payer), '', '');
        emit log_named_uint("Local balance after redeem", ajAssetBalanceOf(address(_ajERC20Terminal)));

        evm.stopPrank();
        assertTrue(true);
    }
}
