// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./AppleJuiceERC20.sol";
import "./interfaces/IAppleJuiceStrategy.sol";

import "jbx/interfaces/IJBController.sol";
import "jbx/interfaces/IJBDirectory.sol";
import "jbx/interfaces/IJBPaymentTerminal.sol";
import "jbx/interfaces/IJBRedemptionTerminal.sol";

import "jbx/libraries/JBCurrencies.sol";
import "jbx/libraries/JBTokens.sol";

import "jbx/structs/JBTokenAmount.sol";

/*
Thirst is the craving for potable fluids, resulting in the basic instinct of animals to drink.
It is an essential mechanism involved in fluid balance.
*/

contract AppleJuiceTerminal is
    IJBPaymentTerminal,
    IJBRedemptionTerminal,
    AppleJuiceERC20
{
    error AppleJuiceTerminal_NoIndirectProjectcontribution();
    error AppleJuiceTerminal_OnlyEtherAccepted();

    IJBController immutable jbController;
    IJBDirectory immutable jbDirectory;

    uint256 immutable appleJuiceId;

    IAppleJuiceStrategy[] public currentStrategies;

    // if this terminal is added as terminal of a project, their whole overflow will reflect eth in currently open position too
    function currentEthOverflowOf(uint256 _projectId)
        external
        view
        override
        returns (uint256)
    {
        return
            (balanceOf[address(uint160(_projectId))] * totalAssets()) /
            totalSupply;
    }

    function totalAssets() public view returns (uint256 _totalEthAmount) {
        uint256 _numberOfStrategies = currentStrategies.length;

        for (uint256 i; i < _numberOfStrategies; i++) {
            _totalEthAmount += currentStrategies[i].totalAssets();
        }

        _totalEthAmount += address(this).balance;
    }

    function acceptsToken(address _token)
        external
        pure
        override
        returns (bool)
    {
        return (_token == JBTokens.ETH);
    }

    function currencyForToken(address _token)
        external
        pure
        override
        returns (uint256)
    {
        // Avoid the unused parameter compilation warning while not resulting in any extra bytecode
        _token;
        return JBCurrencies.ETH;
    }

    function decimalsForToken(address _token)
        external
        pure
        override
        returns (uint256)
    {
        _token;
        return 18;
    }

    constructor(IJBDirectory _directory, uint256 _appleJuiceId) {
        jbDirectory = _directory;
        jbController = IJBController(_directory.controllerOf(_appleJuiceId));
        appleJuiceId = _appleJuiceId;
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
    ) external payable override returns (uint256 beneficiaryTokenCount) {
        if (msg.value == 0) revert AppleJuiceTerminal_OnlyEtherAccepted();
        if (
            _projectId != 0 &&
            !jbDirectory.isTerminalOf(
                _projectId,
                IJBPaymentTerminal(msg.sender)
            )
        ) revert AppleJuiceTerminal_NoIndirectProjectcontribution();

        // amount of token to mint
        beneficiaryTokenCount = (_amount * totalSupply) / totalAssets();

        // Mint for beneficiary or for a project?
        _projectId == 0
            ? _mint(_beneficiary, beneficiaryTokenCount)
            : _mintForProject(_projectId, beneficiaryTokenCount);

        // Deposit in strategies
        // Alternative: group and deposit once every X hours
        uint256 _ethToDeposit = address(this).balance;
        uint256 _numberOfStrategies = currentStrategies.length;
        for (uint256 i; i < _numberOfStrategies; i++) {
            currentStrategies[i].deposit{
                value: _ethToDeposit / _numberOfStrategies
            }();
        }
    }

    function addToBalanceOf(
        uint256 _projectId,
        uint256 _amount,
        address _token,
        string calldata _memo,
        bytes calldata _metadata
    ) external payable override {}

    function redeemTokensOf(
        address _holder,
        uint256 _projectId,
        uint256 _count,
        address _token,
        uint256 _minReturnedTokens,
        address payable _beneficiary,
        string calldata _memo,
        bytes calldata _metadata
    ) external override returns (uint256 reclaimAmount) {
        // get total eth
        // eth received = _amount * totalEth(strats + this contract) / totalSupply
        // burn
        // reduce positions by sending to _beneficiary
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _interfaceId == type(IJBPaymentTerminal).interfaceId ||
            _interfaceId == type(IJBRedemptionTerminal).interfaceId;
    }
}
