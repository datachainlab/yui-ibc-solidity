// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "../lib/strings.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./IICS20Bank.sol";

contract ICS20Bank is Context, AccessControl, IICS20Bank {
    using strings for *;
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Mapping from token ID to account balances
    mapping(string => mapping(address => uint256)) private _balances;

    constructor() {
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function setOperator(address operator) virtual public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "must have admin role to set new operator");
        _setupRole(OPERATOR_ROLE, operator);
    }

    function balanceOf(address account, string calldata id) virtual external view returns (uint256) {
        require(account != address(0), "ICS20Bank: balance query for the zero address");
        return _balances[id][account];
    }

    function transferFrom(address from, address to, string calldata id, uint256 amount) override virtual external {
        require(to != address(0), "ICS20Bank: transfer to the zero address");
        require(
            from == _msgSender() || hasRole(OPERATOR_ROLE, _msgSender()),
            "ICS20Bank: caller is not owner nor approved"
        );

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ICS20Bank: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;
    }

    function mint(address account, string calldata id, uint256 amount) override virtual external {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "ICS20Bank: must have minter role to mint");
        _mint(account, id, amount);
    }

    function burn(address account, string calldata id, uint256 amount) override virtual external {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "ICS20Bank: must have minter role to mint");
        _burn(account, id, amount);
    }

    function deposit(
        address tokenContract,
        uint256 amount,
        address receiver
    ) virtual external {
        require(tokenContract.isContract());
        require(IERC20(tokenContract).transferFrom(_msgSender(), address(this), amount));
        _mint(receiver, _genDenom(tokenContract), amount);
    }

    function withdraw(
        address tokenContract,
        uint256 amount,
        address receiver
    ) virtual external {
        require(tokenContract.isContract());
        _burn(_msgSender(), _genDenom(tokenContract), amount);
        require(IERC20(tokenContract).transfer(receiver, amount));
    }

    function _mint(address account, string memory id, uint256 amount) virtual internal {
        _balances[id][account] += amount;
    }

    function _burn(address account, string memory id, uint256 amount) virtual internal {
        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ICS20Bank: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;
    }

    function _genDenom(address tokenContract) virtual pure internal returns (string memory) {
        return strings.addressToString(tokenContract);
    }
}
