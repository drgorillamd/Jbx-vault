// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IJYAStrategy.sol";

import "jbx/interfaces/IJBPaymentTerminal.sol";
import "jbx/interfaces/IJBRedemptionTerminal.sol";

import "jbx/structs/JBTokenAmount.sol";

// launch:
interface IAppleJuiceTerminal is IJBPaymentTerminal, IJBRedemptionTerminal {
    IJYAStrategy[] currentStrategies; // if this terminal is added as terminal of a project, their whole overflow will reflect eth in currently open position too

    function currentEthOverflowOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function pay(
        uint256 _projectId,
        uint256 _amount,
        address _token,
        address _beneficiary,
        uint256 _minReturnedTokens,
        bool _preferClaimedTokens,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable returns (uint256 beneficiaryTokenCount);

    function addToBalanceOf(
        uint256 _projectId,
        uint256 _amount,
        address _token,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable;

    function redeemTokensOf(
        address _holder,
        uint256 _projectId,
        uint256 _count,
        address _token,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string calldata _memo,
        bytes calldata _metadata
    ) external returns (uint256 reclaimAmount);

    // add to the array
    function addStrategy(address _strategy) external onlyOwner;

    // ragequit strat then remove from array (eth are now in this contract)
    function removeStrategy(address _strategy) external onlyOwner;
}
