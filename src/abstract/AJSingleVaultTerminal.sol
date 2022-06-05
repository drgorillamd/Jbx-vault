// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "jbx/libraries/JBOperations.sol";

import "../interfaces/IERC4626.sol";

import "./AJPayoutRedemptionTerminal.sol";

import "../enums/AJReserveReason.sol";
import "../enums/AJAssignReason.sol";

abstract contract AJSingleVaultTerminal is AJPayoutRedemptionTerminal {
    mapping(uint256 => Vault) projectVault;

    /**
        @notice Adds the `_amount` of assets to the projects accounting and allows the funds to be assigned
    */
    function _assignAssets(
        uint256 _projectId,
        uint256 _amount,
        AJAssignReason _reason
    ) internal virtual override {
        Vault storage _vault = projectVault[_projectId];

        // We never deposit on 'Pay' or 'FeesPaid' to keep them low gas
        if (_reason != AJAssignReason.Pay && _reason != AJAssignReason.FeesPaid) {

            int256 _targetLocalBalanceDelta = _targetLocalBalanceDelta(_vault, int256(_amount));
            // Depositing more (usually) does not increase the gas cost
            // so we use this opertunity to fill up to the target amount
            if (_targetLocalBalanceDelta > 0) {
                // Check if the balance is already above the target
                uint256 _depositAmount = _amount +
                    uint256(_targetLocalBalanceDelta);

                // Update the accounting
                _vault.state.localBalance -= uint256(_targetLocalBalanceDelta);
                _vault.state.shares += _deposit(_vault, _depositAmount);
                return;
            }
        }

        _vault.state.localBalance += _amount;
        return;
    }

    /**
        @notice Removes the `_amount` of assets from the projects accounting and reserves the `_amount` in this contract
        @dev Revert if its not possible to reserve the `_amount`
    */
    function _reserveAssets(
        uint256 _projectId,
        uint256 _amount,
        AJReserveReason _reason
    ) internal virtual override {
        Vault storage _vault = projectVault[_projectId];

        // If no vault is set we have to use the local balance
        if (address(_vault.impl) == address(0)) {
            _vault.state.localBalance -= _amount;
            return;
        }

        // Either we have to withdraw from the vault, or this is a `DistributePayoutsOf` and we do housekeeping
        if (
            _amount > _vault.state.localBalance ||
            _reason == AJReserveReason.DistributePayoutsOf
        ) {
            uint256 _withdrawAmount = _amount;
            // Withdrawing more (usually) does not increase the gas cost
            // so we use this opertunity to fill up to the target amount
            int256 _targetLocalBalanceDelta = _targetLocalBalanceDelta(_vault, -int256(_amount));
            // we should always have enough shares to do this since we just checked how much we have in the vault
            if (_targetLocalBalanceDelta < 0) {
                _withdrawAmount += uint256(-_targetLocalBalanceDelta);
            }

            // Update the accounting
            _vault.state.localBalance -= _withdrawAmount - _amount;
            _vault.state.shares -= _withdraw(_vault, _withdrawAmount);
            return;
        }

        // The other operations such as RedeemTokensOf, UseAllowanceOf and ProcessFees use the local balance
        _vault.state.localBalance -= _amount;
    }

    function currentEthOverflowOf(uint256 _projectId)
        external
        view
        virtual
        override
        returns (uint256 _assets)
    {
        uint256 _assetsInVault;
        Vault storage _vault = projectVault[_projectId];

        // If an vault is set, get the amount of assets that we have deposited
        if (address(_vault.impl) != address(0)) {
            _assetsInVault = _vault.impl.previewRedeem(_vault.state.shares);
        }

        // TODO: convert to ETH
        _assets = _assetsInVault + _vault.state.localBalance;
    }

    function _targetLocalBalanceDelta(Vault storage _vault, int256 _change)
        internal
        returns (int256 delta)
    {
        // Get the amount of assets in the vault
        // TODO: Should we use `convertToAssets` or `previewRedeem` here?
        uint256 _vaultAssets = _vault.impl.convertToAssets(_vault.state.shares);
        uint256 _totalAssets = _vault.state.localBalance + _vaultAssets;

        if(_change >= 0){
            // Add change to the total balance
            _totalAssets += uint256(_change);
        }else{
            // Subtract the abs of change from the total balance
            _totalAssets -= uint256(-_change);
        }

        // calculate the target local amount
        uint256 _targetLocalBalance = (_totalAssets / 1_000_000) *
            _vault.config.targetLocalBalancePPM;

        delta = int256(_vault.state.localBalance) - int256(_targetLocalBalance);
    }

    function _withdraw(Vault storage _vault, uint256 _assetAmount)
        internal
        virtual
        returns (uint256 sharesCost);

    function _deposit(Vault storage _vault, uint256 _assetAmount)
        internal
        virtual
        returns (uint256 sharesReceived);
}

// TODO: move structs
struct Vault {
    IERC4626 impl;
    VaultConfig config;
    VaultState state;
}

struct VaultState {
    uint256 localBalance;
    uint256 shares;
}

struct VaultConfig {
    uint256 targetLocalBalancePPM;
}
