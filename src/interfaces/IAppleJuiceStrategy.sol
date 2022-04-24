// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "jbx/interfaces/IJBPaymentTerminal.sol";
import "jbx/interfaces/IJBRedemptionTerminal.sol";

interface IAppleJuiceStrategy {
    // returns the total amount of eth in this current strategy (then used to compute overflow)
    function netInPosition() external view returns (uint256 _amount);

    function deposit() external;

    function withdraw(uint256 _amount, address _beneficiary) external;
}
