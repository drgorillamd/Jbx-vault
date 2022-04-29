pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract AppleJuiceERC20 is IERC20Metadata {
    // move to interface:
    error AppleJuiceERC20_TransferedAmountExceedBalance();
    error AppleJuiceERC20_BurnedAmountExceedBalance();
    error AppleJuiceERC20_SpentAllowanceExceedCurrentAllowance();

    event TransferToProject(address, uint256, uint256);
    //---

    uint8 public constant override decimals = 18;

    string public constant override name = "AppleJuice";

    string public constant override symbol = "THIRST";

    // owner or address(projectId) => balance
    mapping(address => uint256) public override balanceOf;

    // Owner => Spender => amount
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 fromBalance = balanceOf[from];
        if (fromBalance < amount)
            revert AppleJuiceERC20_TransferedAmountExceedBalance();

        unchecked {
            balanceOf[from] = fromBalance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _mintForProject(uint256 _projectId, uint256 _amount) internal {
        balanceOf[address(uint160(_projectId))] += _amount;
        totalSupply += _amount;
        emit TransferToProject(address(0), _projectId, _amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        uint256 accountBalance = balanceOf[account];
        if (accountBalance < amount)
            revert AppleJuiceERC20_BurnedAmountExceedBalance();
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount)
                revert AppleJuiceERC20_SpentAllowanceExceedCurrentAllowance();

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
