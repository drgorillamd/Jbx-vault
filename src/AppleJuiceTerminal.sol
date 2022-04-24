// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IJYAStrategy.sol";

import "jbx/interfaces/IJBPaymentTerminal.sol";
import "jbx/interfaces/IJBRedemptionTerminal.sol";

import "jbx/structs/JBTokenAmount.sol";

// launch:
contract AppleJuiceTerminal is IJBPaymentTerminal, IJBRedemptionTerminal {
    IJYAStrategy[] currentStrategies;

    // if this terminal is added as terminal of a project, their whole overflow will reflect eth in currently open position too
    function currentEthOverflowOf(uint256 _projectId)
        external
        view
        returns (uint256)
    {
        // for every currentStrategies:
        // overflow += token balance projectId * currentStrategies[i].netInPosition / totalSupply
    }

    constructor() {
        //directory
    }

    function pay(
        uint256 _projectId,
        uint256 _amount,
        address _token,
        address _beneficiary,
        uint256 _minReturnedTokens,
        bool _preferClaimedTokens,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable returns (uint256 beneficiaryTokenCount) {
        // if project id != 0 -> require msg.sender is directory of project id (no individual contribution for other projects)
        // (directory.isTerminalOf(_projectId, msg.sender)
        // get total eth
        // amount of token to mint = _amount * totalSupply / totalEth
        // beneficiaryTokenCount = IJBController(directory.controllerOf(_projectId)).mintTokensOf(
        //   _projectId,
        //   _tokenCount,
        //   _beneficiary,
        //   '',
        //   _preferClaimedTokens,
        //   true
        // );
        // spread the juice -> for each strategy, deposit() value:_amount/currentStrategies.length
    }

    function addToBalanceOf(
        uint256 _projectId,
        uint256 _amount,
        address _token,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable {}

    function redeemTokensOf(
        address _holder,
        uint256 _projectId,
        uint256 _count,
        address _token,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string calldata _memo,
        bytes calldata _metadata
    ) external returns (uint256 reclaimAmount) {
        // get total eth
        // eth received = _amount * totalEth / totalSupply
        // burn
        // reduce positions
    }
}
