// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "jbx/libraries/JBOperations.sol";

// Temporarily copied to this repo so we can PoC it before having to modify the actual one
import "./JBPayoutRedemptionPaymentTerminal.sol";

/*
Thirst is the craving for potable fluids, resulting in the basic instinct of animals to drink.
It is an essential mechanism involved in fluid balance.
*/

abstract contract AJPayoutRedemptionTerminal is
    JBPayoutRedemptionPaymentTerminal
{
    /**
        @notice Registers the `_amount` as being available for `_projectId`s strategy and allows the funds to be assigned
    */
    function _assignAssets(uint256 _projectId, uint256 _amount)
        internal
        virtual;

    /**
        @notice Make sure the local balance of `_projectId` is ready to withdraw the `_amount` of assets
        @dev Revert if its not possible to reserve the `_amount`
    */
    function _reserveAssets(uint256 _projectId, uint256 _amount)
        internal
        virtual;

    /**
    @notice
    Receives funds belonging to the specified project.

    @param _projectId The ID of the project to which the funds received belong.
    @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
    ignored: _token The token being paid. This terminal ignores this property since it only manages one currency. 
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Extra data to pass along to the emitted event.
  */
    function addToBalanceOf(
        uint256 _projectId,
        uint256 _amount,
        address,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable virtual override isTerminalOf(_projectId) {
        // If this terminal's token isn't ETH, make sure no msg.value was sent, then transfer the tokens in from msg.sender.
        if (token != JBTokens.ETH) {
            // Amount must be greater than 0.
            if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

            // Transfer tokens to this terminal from the msg sender.
            _transferFrom(msg.sender, payable(address(this)), _amount);
        }
        // If the terminal's token is ETH, override `_amount` with msg.value.
        else _amount = msg.value;

        _addToBalanceOf(_projectId, _amount, _memo, _metadata);
        _assignAssets(_projectId, _amount);
    }

    /**
    @notice
    Distributes payouts for a project with the distribution limit of its current funding cycle.

    @dev
    Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner.

    @dev
    Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function.

    @dev
    All funds distributed outside of this contract or any feeless terminals incure the protocol fee.

    @param _projectId The ID of the project having its payouts distributed.
    @param _amount The amount of terminal tokens to distribute, as a fixed point number with same number of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's distribution limit currency.
    ignored: _token The token being distributed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum number of terminal tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with the same number of decimals as this terminal.
    @param _memo A memo to pass along to the emitted event.

    @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  */
    function distributePayoutsOf(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        address,
        uint256 _minReturnedTokens,
        string calldata _memo
    )
        external
        virtual
        override
        returns (uint256 netLeftoverDistributionAmount)
    {
        _reserveAssets(_projectId, _amount);

        return
            _distributePayoutsOf(
                _projectId,
                _amount,
                _currency,
                _minReturnedTokens,
                _memo
            );
    }

    /**
    @notice
    Contribute tokens to a project.

    @param _projectId The ID of the project being paid.
    @param _amount The amount of terminal tokens being received, as a fixed point number with the same amount of decimals as this terminal. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
    ignored: _token The token being paid. This terminal ignores this property since it only manages one token. 
    @param _beneficiary The address to mint tokens for and pass along to the funding cycle's delegate.
    @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
    @param _preferClaimedTokens A flag indicating whether the request prefers to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
    @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.  A data source can alter the memo before emitting in the event and forwarding to the delegate.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return beneficiaryTokenCount The number of tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  */
    function pay(
        uint256 _projectId,
        uint256 _amount,
        address,
        address _beneficiary,
        uint256 _minReturnedTokens,
        bool _preferClaimedTokens,
        string calldata _memo,
        bytes calldata _metadata
    )
        external
        payable
        virtual
        override
        isTerminalOf(_projectId)
        returns (uint256 beneficiaryTokenCount)
    {
        // ETH shouldn't be sent if this terminal's token isn't ETH.
        if (token != JBTokens.ETH) {
            if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

            // Transfer tokens to this terminal from the msg sender.
            _transferFrom(msg.sender, payable(address(this)), _amount);
        }
        // If this terminal's token is ETH, override _amount with msg.value.
        else _amount = msg.value;

        beneficiaryTokenCount = _pay(
            _amount,
            msg.sender,
            _projectId,
            _beneficiary,
            _minReturnedTokens,
            _preferClaimedTokens,
            _memo,
            _metadata
        );

        _assignAssets(_projectId, _amount);
    }

    /**
    @notice
    Allows a project to send funds from its overflow up to the preconfigured allowance.

    @dev
    Only a project's owner or a designated operator can use its allowance.

    @dev
    Incurs the protocol fee.

    @param _projectId The ID of the project to use the allowance of.
    @param _amount The amount of terminal tokens to use from this project's current allowance, as a fixed point number with the same amount of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's overflow allowance currency.
    ignored: _token The token being distributed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum number of tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with 18 decimals.
    @param _beneficiary The address to send the funds to.
    @param _memo A memo to pass along to the emitted event.

    @return netDistributedAmount The amount of tokens that was distributed to the beneficiary, as a fixed point number with the same amount of decimals as the terminal.
  */
    function useAllowanceOf(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        address,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string memory _memo
    )
        external
        virtual
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            JBOperations.USE_ALLOWANCE
        )
        returns (uint256 netDistributedAmount)
    {
        // TODO: handle the currency
        _reserveAssets(_projectId, _amount);

        return
            _useAllowanceOf(
                _projectId,
                _amount,
                _currency,
                _minReturnedTokens,
                _beneficiary,
                _memo
            );
    }

    /**
    @notice
    Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.

    @dev
    Only a token holder or a designated operator can redeem its tokens.

    @param _holder The account to redeem tokens for.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
    ignored: _token The token being reclaimed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
    @param _beneficiary The address to send the terminal tokens to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  */
    function redeemTokensOf(
        address _holder,
        uint256 _projectId,
        uint256 _tokenCount,
        address,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string memory _memo,
        bytes memory _metadata
    )
        external
        virtual
        override
        requirePermission(_holder, _projectId, JBOperations.REDEEM)
        returns (uint256 reclaimAmount)
    {
        // Logic to `_reserveAssets` is handled in the `_redeemTokensAJ` method, since we don't know what amount to reserve
        return
            _redeemTokensAJ(
                _holder,
                _projectId,
                _tokenCount,
                _minReturnedTokens,
                _beneficiary,
                _memo,
                _metadata
            );
    }

    //*********************************************************************//
    // --------------------- private helper functions -------------------- //
    //*********************************************************************//

    /**
    @notice
    Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.

    @dev
    Only a token holder or a designated operator can redeem its tokens. Slight rename from original so we dont have to make it `internal virtual`

    @param _holder The account to redeem tokens for.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
    @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
    @param _beneficiary The address to send the terminal tokens to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  */
    function _redeemTokensAJ(
        address _holder,
        uint256 _projectId,
        uint256 _tokenCount,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string memory _memo,
        bytes memory _metadata
    ) private returns (uint256 reclaimAmount) {
        // Can't send reclaimed funds to the zero address.
        if (_beneficiary == address(0)) revert REDEEM_TO_ZERO_ADDRESS();

        // Define variables that will be needed outside the scoped section below.
        // Keep a reference to the funding cycle during which the redemption is being made.
        JBFundingCycle memory _fundingCycle;

        // Scoped section prevents stack too deep. `_delegate` only used within scope.
        {
            IJBRedemptionDelegate _delegate;

            // Record the redemption.
            (_fundingCycle, reclaimAmount, _delegate, _memo) = store
                .recordRedemptionFor(
                    _holder,
                    _projectId,
                    _tokenCount,
                    _memo,
                    _metadata
                );

            // The amount being reclaimed must be at least as much as was expected.
            if (reclaimAmount < _minReturnedTokens)
                revert INADEQUATE_RECLAIM_AMOUNT();

            // Burn the project tokens.
            if (_tokenCount > 0)
                IJBController(directory.controllerOf(_projectId)).burnTokensOf(
                    _holder,
                    _projectId,
                    _tokenCount,
                    "",
                    false
                );

            // If a delegate was returned by the data source, issue a callback to it.
            if (_delegate != IJBRedemptionDelegate(address(0))) {
                JBDidRedeemData memory _data = JBDidRedeemData(
                    _holder,
                    _projectId,
                    _tokenCount,
                    JBTokenAmount(token, reclaimAmount, decimals, currency),
                    _beneficiary,
                    _memo,
                    _metadata
                );
                _delegate.didRedeem(_data);
                emit DelegateDidRedeem(_delegate, _data, msg.sender);
            }
        }

        // Send the reclaimed funds to the beneficiary.
        if (reclaimAmount > 0) {
            _reserveAssets(_projectId, reclaimAmount);
            _transferFrom(address(this), _beneficiary, reclaimAmount);
        }

        emit RedeemTokens(
            _fundingCycle.configuration,
            _fundingCycle.number,
            _projectId,
            _holder,
            _beneficiary,
            _tokenCount,
            reclaimAmount,
            _memo,
            _metadata,
            msg.sender
        );
    }
}
