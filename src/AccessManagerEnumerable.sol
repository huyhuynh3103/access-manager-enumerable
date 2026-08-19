// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessManager} that adds enumerable views for role members
 * and configured function selectors per target.
 *
 * Analogous to {AccessControlEnumerable} for {AccessControl}.
 *
 * WARNING: {getRoleMembers} and {getTargetFunctionSelectors} copy the full set to
 * memory. Query them off-chain or in view contexts only — they have unbounded gas cost.
 */
abstract contract AccessManagerEnumerable is AccessManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // roleId => set of accounts that currently hold the role
    mapping(uint64 roleId => EnumerableSet.AddressSet) private _roleMembers;

    // target => set of selectors that have been explicitly configured via setTargetFunctionRole
    // ponytail: selectors are never removed; role assignment can change but the selector stays configured
    mapping(address target => EnumerableSet.Bytes32Set) private _targetSelectors;

    // ─── Role member enumeration ─────────────────────────────────────────────

    function getRoleMember(uint64 roleId, uint256 index) public view returns (address) {
        return _roleMembers[roleId].at(index);
    }

    function getRoleMemberCount(uint64 roleId) public view returns (uint256) {
        return _roleMembers[roleId].length();
    }

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

    function getTargetFunctionSelectors(address target) public view returns (bytes4[] memory) {
        bytes32[] memory raw = _targetSelectors[target].values();
        bytes4[] memory selectors = new bytes4[](raw.length);
        for (uint256 i = 0; i < raw.length; ++i) {
            selectors[i] = bytes4(raw[i]);
        }
        return selectors;
    }

    // ─── Hooks ───────────────────────────────────────────────────────────────

    function _grantRole(
        uint64 roleId,
        address account,
        uint32 grantDelay,
        uint32 executionDelay
    ) internal virtual override returns (bool) {
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
