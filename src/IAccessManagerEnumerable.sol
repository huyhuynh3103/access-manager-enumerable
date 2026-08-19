// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAccessManagerEnumerable is IERC165 {
    function getRoleMember(uint64 roleId, uint256 index) external view returns (address);
    function getRoleMemberCount(uint64 roleId) external view returns (uint256);
    function getRoleMembers(uint64 roleId) external view returns (address[] memory);

    function getTargetFunctionSelector(address target, uint256 index) external view returns (bytes4);
    function getTargetFunctionSelectorCount(address target) external view returns (uint256);
    function getTargetFunctionSelectors(address target) external view returns (bytes4[] memory);
}
