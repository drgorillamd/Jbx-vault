// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "jbx/interfaces/IJBPayDelegate.sol";
import "jbx/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import "jbx/structs/JBTokenAmount.sol";

import "keep3r/interfaces/IKeep3r.sol";

contract PayDelegate {
    error unAuth();

    IJBPayoutRedemptionPaymentTerminal public terminal;

    uint256 public immutable projectId;

    IKeep3r public keep3r;

    constructor(
        IJBPayoutRedemptionPaymentTerminal _terminal,
        uint256 _projectId,
        IKeep3r _keep3r
    ) {
        terminal = _terminal;
        projectId = _projectId;
        keep3r = _keep3r;
    }

    function didPay(JBDidPayData calldata _data) external {
        if (msg.sender != address(terminal)) revert unAuth();

        JBTokenAmount calldata _bundledAmount = _data.amount;

        //use overflow allowance and transfer to this vault
        terminal.useAllowanceOf(
            projectId,
            _bundledAmount.value,
            _bundledAmount.currency,
            _bundledAmount.value,
            payable(address(this)),
            ""
        );

        //Check lido stake apy + aave borrow apy

        //Lido: deposit ETH, get stETH

        //AAVE: deposit stETH

        //AAVE: borrow ETH

        //Lido: deposit ETH, get stETH

        //AAVE: deposit stETH
    }
}
