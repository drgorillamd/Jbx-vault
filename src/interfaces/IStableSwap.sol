// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

/**
 * @title StableSwap Curve interface
 */
interface IStableSwap {
    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256 amountOut);

    function coins(uint256 i) external returns (address token);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256 nonpayable);
}
