pragma solidity 0.8.6;

import "../interfaces/IERC4626.sol";
import "../interfaces/ILido.sol";
import "../interfaces/IStableSwap.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

address CURVE_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
/**
 @notice
 AppleJuice terminal ERC4626 strategy: Lido stETH
*/

contract LidoJuice is IERC4626, ERC20 {
    error LidoJuice_zeroEth();
    error LidoJuice_wrongStETHReceived();
    error LidoJuice_insufficientEthReceived();

    ILido immutable stETH;
    IStableSwap immutable curvePool;

    uint256 constant MIN_SLIPPAGE = 100; // 1%

    int128 immutable curveEthIndex;
    int128 immutable curveStEthIndex;

    constructor(ILido _stETH, IStableSwap _curvePool) ERC20("LidoJuice", "AstETH") {
        stETH = _stETH;

        curvePool = _curvePool;
        curveStEthIndex = _curvePool.coins(0) == address(_stETH) ? 0 : 1; // 2-assets pool
        curveEthIndex = curveStEthIndex == 0 ? 1 : 0;
    }

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view override returns (address _asset) {
        return address(this);
    }

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets()
        external
        view
        override
        returns (uint256 _totalAssets)
    {
        return stETH.balanceOf(address(this));
    }

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver)
        external
        payable
        override
        returns (uint256 shares)
    {
        if (msg.value == 0) revert LidoJuice_zeroEth();

        // Compute share of the asset managed by this vault
        shares = (msg.value * totalSupply()) / stETH.balanceOf(address(this));

        // TODO:Mint to external senders allowed? Or send to AppleJuiceTerminal only (and revert for other callers then)
        _mint(msg.sender, shares);

        // Stake
        uint256 _received = stETH.submit{value: msg.value}(address(this));

        // Should be 1:1
        if (_received != msg.value) revert LidoJuice_wrongStETHReceived();
    }

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 shares, address receiver)
        external
        payable
        override
        returns (uint256 assets)
    {
        // Compute the eth value of the share amount wanted
        uint256 _ethInNeeded = (shares * stETH.balanceOf(address(this))) /
            totalSupply();

        if (msg.value < _ethInNeeded)
            revert LidoJuice_insufficientEthReceived();

        _mint(shares, msg.sender);

        uint256 _received = stETH.submit{value: msg.value}(address(this));
        if (_received != _ethInNeeded) revert LidoJuice_wrongStETHReceived();

        // Reimburse extra eth sent
        payable(msg.sender).call{value: msg.value - _ethInNeeded}("");
    }

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`. -> for now, exiting via Curve or 1inch
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external override returns (uint256 shares) {
        // This is tricky with curve (not impossible, simulate call to exchange(..), use a bit of
        // assembly and a try-catch, but is it really worth it?)
    }

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external override returns (uint256 assets) {

        uint256 _stEthOwned = (shares * stETH.balanceOf(address(this)) / totalSupply());
        uint256 _ethReceivedOnCurve = curvePool.get_dy(curveStEthIndex, curveEthIndex, _stEthOwned);
        uint256 _minReceived = _ethReceivedOnCurve * MIN_SLIPPAGE / 10000;

        _burn(shares); // Revert on insuf balance

        IERC20(address(stETH)).approve(address(curvePool), _stEthOwned);
        assets = curvePool.exchange(curveStEthIndex, curveEthIndex, _stEthOwned, _minReceived, receiver);
    }

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets)
        external
        view
        override
        returns (uint256 shares)
    {

    }

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares)
        external
        view
        override
        returns (uint256 assets)
    {}

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner)
        external
        view
        override
        returns (uint256 maxAssets)
    {}

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets)
        external
        view
        override
        returns (uint256 shares)
    {}

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner)
        external
        view
        override
        returns (uint256 maxShares)
    {}

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares)
        external
        view
        override
        returns (uint256 assets)
    {}

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256 maxAssets)
    {}

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets)
        external
        view
        override
        returns (uint256 shares)
    {}

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner)
        external
        view
        override
        returns (uint256 maxShares)
    {}

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares)
        external
        view
        override
        returns (uint256 assets)
    {}

    function _simulate(address _target, bytes _calldata, uint256 _msgValue) internal view returns(bool _success, bytes _data) {
        try this._leRevertor(_target, _calldata, _msgValue) {
            // Shouldn't get here
        } catch(bytes memory _returnedData) {
            return (_returnedData.length == 0, _returnedData);
        }
    }

    function _leRevertor(address _target, bytes _calldata, uint256 _msgValue) internal returns(bytes _returnedValue) {
        assembly {
            let returnStatus := call(gas(), _target, _msgValue, _calldata, _calldata.length, 0, 0)
            
            // Call fails, return an empty byte
            if iszero(returnStatus) {
                revert(0)
            }

            // Call successful, copy the return data in free mem then revert with the data as reason
            let returnDataPlaceholder := mload(0x40)
            returndatacopy(returnDataPlaceholder, 0, returndatasize())
            revert(returnDataPlaceholder, add(returnDataPlaceholder,  returndatasize()))
        }
    }
}
