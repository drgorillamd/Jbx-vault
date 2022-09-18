// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IAppleJuiceStrategy.sol";

import "jbx/interfaces/IJBPaymentTerminal.sol";
import "jbx/interfaces/IJBRedemptionTerminal.sol";

import "jbx/structs/JBTokenAmount.sol";

// launch:
interface IAppleJuiceTerminal is IJBPaymentTerminal, IJBRedemptionTerminal {
    // add to the array
    function addStrategy(address _strategy) external;

    // ragequit strat then remove from array (eth are now in this contract)
    function removeStrategy(address _strategy) external;
}
