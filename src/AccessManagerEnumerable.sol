// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAccessManagerEnumerable} from "./IAccessManagerEnumerable.sol";

/**
 * @dev Extension of {AccessManager} that adds enumerable views for role members
 * and configured function selectors per target.
 *
 * Analogous to {AccessControlEnumerable} for {AccessControl}.
 *
 * WARNING: {getRoleMembers} and {getTargetFunctionSelectors} copy the full set to
 * memory. Query them off-chain or in view contexts only — they have unbounded gas cost.
 */
abstract contract AccessManagerEnumerable is IAccessManagerEnumerable, AccessManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // roleId => set of accounts that currently hold the role
    mapping(uint64 roleId => EnumerableSet.AddressSet) private _roleMembers;

    // target => set of selectors that have been explicitly configured via setTargetFunctionRole
    // ponytail: selectors are never removed; role assignment can change but the selector stays configured
    mapping(address target => EnumerableSet.Bytes32Set) private _targetSelectors;

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IAccessManagerEnumerable).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // ─── Role member enumeration ─────────────────────────────────────────────

    /**
     * @dev Returns the account at position `index` in the granted-members set for `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. See {getRoleMembers}.
     */
    function getRoleMember(uint64 roleId, uint256 index) public view returns (address) {
        return _roleMembers[roleId].at(index);
    }

    /**
     * @dev Returns the number of accounts that have been granted `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. See {getRoleMembers}.
     */
    function getRoleMemberCount(uint64 roleId) public view returns (uint256) {
        return _roleMembers[roleId].length();
    }

    /**
     * @dev Returns all accounts that have been granted `roleId`.
     *
     * NOTE: Includes accounts whose grant delay has not yet elapsed. Such accounts appear
     * in this list but {hasRole} may return false for them until the delay passes. Always
     * verify active membership with {hasRole} before acting on enumerated results.
     *
     * WARNING: This operation copies the entire set to memory and has unbounded gas cost.
     * Only call from off-chain or view contexts.
     */
    function getRoleMembers(uint64 roleId) public view returns (address[] memory) {
        return _roleMembers[roleId].values();
    }

    // ─── Target selector enumeration ─────────────────────────────────────────

    function getTargetFunctionSelector(address target, uint256 index) public view returns (bytes4) {
        return bytes4(_targetSelectors[target].at(index));
    }

    function getTargetFunctionSelectorCount(address target) public view returns (uint256) {
        return _targetSelectors[target].length();
    }

    /**
     * @dev Returns all function selectors that have been explicitly configured via
     * {setTargetFunctionRole} for `target`.
     *
     * WARNING: This operation copies the entire set to memory and has unbounded gas cost.
     * Only call from off-chain or view contexts.
     */
    function getTargetFunctionSelectors(address target) public view returns (bytes4[] memory) {
        bytes32[] memory raw = _targetSelectors[target].values();
        bytes4[] memory selectors = new bytes4[](raw.length);
        for (uint256 i = 0; i < raw.length; ++i) {
            selectors[i] = bytes4(raw[i]);
        }
        return selectors;
    }

    // ─── Hooks ───────────────────────────────────────────────────────────────

    function _grantRole(uint64 roleId, address account, uint32 grantDelay, uint32 executionDelay)
        internal
        virtual
        override
        returns (bool)
    {
        bool newMember = super._grantRole(roleId, account, grantDelay, executionDelay);
        if (newMember) {
            _roleMembers[roleId].add(account);
        }
        return newMember;
    }

    function _revokeRole(uint64 roleId, address account) internal virtual override returns (bool) {
        bool revoked = super._revokeRole(roleId, account);
        if (revoked) {
            _roleMembers[roleId].remove(account);
        }
        return revoked;
    }

    function _setTargetFunctionRole(address target, bytes4 selector, uint64 roleId) internal virtual override {
        super._setTargetFunctionRole(target, selector, roleId);
        _targetSelectors[target].add(bytes32(selector));
    }
}
