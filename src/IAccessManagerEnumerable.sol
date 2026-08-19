// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAccessManagerEnumerable is IERC165 {
    /**
     * @dev Returns the account at position `index` in the granted-members set for `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. See {getRoleMembers}.
     */
    function getRoleMember(uint64 roleId, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have been granted `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. See {getRoleMembers}.
     */
    function getRoleMemberCount(uint64 roleId) external view returns (uint256);

    /**
     * @dev Returns all accounts that have been granted `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. Such accounts appear
     * in this list but {IAccessManager-hasRole} may return false for them until the delay
     * passes. Always verify active membership with {IAccessManager-hasRole} before acting
     * on enumerated results.
     *
     * WARNING: This operation copies the entire set to memory and has unbounded gas cost.
     * Only call from off-chain or view contexts.
     */
    function getRoleMembers(uint64 roleId) external view returns (address[] memory);

    function getTargetFunctionSelector(address target, uint256 index) external view returns (bytes4);
    function getTargetFunctionSelectorCount(address target) external view returns (uint256);

    /**
     * @dev Returns all function selectors that have been explicitly configured via
     * {IAccessManager-setTargetFunctionRole} for `target`.
     *
     * WARNING: This operation copies the entire set to memory and has unbounded gas cost.
     * Only call from off-chain or view contexts.
     */
    function getTargetFunctionSelectors(address target) external view returns (bytes4[] memory);
}
