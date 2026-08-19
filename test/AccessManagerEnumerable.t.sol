// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {AccessManagerEnumerable} from "../src/AccessManagerEnumerable.sol";

// Concrete deployment target (abstract → concrete)
contract TestManager is AccessManagerEnumerable {
    constructor(address admin) AccessManager(admin) {}
}

contract AccessManagerEnumerableTest is Test {
    TestManager manager;
    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint64 constant ROLE_A = 1;
    uint64 constant ROLE_B = 2;
    address constant TARGET = address(0xBEEF);

    bytes4 constant SEL_FOO = bytes4(keccak256("foo()"));
    bytes4 constant SEL_BAR = bytes4(keccak256("bar()"));

    function setUp() public {
        manager = new TestManager(admin);
    }

    // ── Role member enumeration ───────────────────────────────────────────────

    function test_ConstructorTracksAdmin() public view {
        assertEq(manager.getRoleMemberCount(manager.ADMIN_ROLE()), 1);
        assertEq(manager.getRoleMember(manager.ADMIN_ROLE(), 0), admin);
    }

    function test_GrantRoleAddsToSet() public {
        vm.prank(admin);
        manager.grantRole(ROLE_A, alice, 0);

        assertEq(manager.getRoleMemberCount(ROLE_A), 1);
        assertEq(manager.getRoleMember(ROLE_A, 0), alice);
    }

    function test_GrantRoleMultipleMembers() public {
        vm.startPrank(admin);
        manager.grantRole(ROLE_A, alice, 0);
        manager.grantRole(ROLE_A, bob, 0);
        vm.stopPrank();

        assertEq(manager.getRoleMemberCount(ROLE_A), 2);

        address[] memory members = manager.getRoleMembers(ROLE_A);
        assertEq(members.length, 2);
    }

    function test_ReGrantSameAccountCountUnchanged() public {
        vm.startPrank(admin);
        manager.grantRole(ROLE_A, alice, 0);
        // re-grant with a different execution delay — not a new member
        manager.grantRole(ROLE_A, alice, 100);
        vm.stopPrank();

        assertEq(manager.getRoleMemberCount(ROLE_A), 1);
    }

    function test_RevokeRoleRemovesFromSet() public {
        vm.startPrank(admin);
        manager.grantRole(ROLE_A, alice, 0);
        manager.revokeRole(ROLE_A, alice);
        vm.stopPrank();

        assertEq(manager.getRoleMemberCount(ROLE_A), 0);
    }

    function test_RenounceRoleRemovesFromSet() public {
        vm.prank(admin);
        manager.grantRole(ROLE_A, alice, 0);

        vm.prank(alice);
        manager.renounceRole(ROLE_A, alice);

        assertEq(manager.getRoleMemberCount(ROLE_A), 0);
    }

    function test_RolesMembersIsolated() public {
        vm.startPrank(admin);
        manager.grantRole(ROLE_A, alice, 0);
        manager.grantRole(ROLE_B, bob, 0);
        vm.stopPrank();

        assertEq(manager.getRoleMemberCount(ROLE_A), 1);
        assertEq(manager.getRoleMemberCount(ROLE_B), 1);
        assertEq(manager.getRoleMember(ROLE_A, 0), alice);
        assertEq(manager.getRoleMember(ROLE_B, 0), bob);
    }

    // ── Target selector enumeration ───────────────────────────────────────────

    function test_SetTargetFunctionRoleTracksSelector() public {
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = SEL_FOO;

        vm.prank(admin);
        manager.setTargetFunctionRole(TARGET, sels, ROLE_A);

        assertEq(manager.getTargetFunctionSelectorCount(TARGET), 1);
        assertEq(manager.getTargetFunctionSelector(TARGET, 0), SEL_FOO);
    }

    function test_SetTargetFunctionRoleMultipleSelectors() public {
        bytes4[] memory sels = new bytes4[](2);
        sels[0] = SEL_FOO;
        sels[1] = SEL_BAR;

        vm.prank(admin);
        manager.setTargetFunctionRole(TARGET, sels, ROLE_A);

        assertEq(manager.getTargetFunctionSelectorCount(TARGET), 2);

        bytes4[] memory result = manager.getTargetFunctionSelectors(TARGET);
        assertEq(result.length, 2);
    }

    function test_ReassignSelectorCountUnchanged() public {
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = SEL_FOO;

        vm.startPrank(admin);
        manager.setTargetFunctionRole(TARGET, sels, ROLE_A);
        // reassign same selector to a different role
        manager.setTargetFunctionRole(TARGET, sels, ROLE_B);
        vm.stopPrank();

        // still one unique selector
        assertEq(manager.getTargetFunctionSelectorCount(TARGET), 1);
        // role assignment updated
        assertEq(manager.getTargetFunctionRole(TARGET, SEL_FOO), ROLE_B);
    }

    function test_SelectorsIsolatedByTarget() public {
        address targetB = address(0xCAFE);
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = SEL_FOO;

        vm.startPrank(admin);
        manager.setTargetFunctionRole(TARGET, sels, ROLE_A);
        sels[0] = SEL_BAR;
        manager.setTargetFunctionRole(targetB, sels, ROLE_A);
        vm.stopPrank();

        assertEq(manager.getTargetFunctionSelectorCount(TARGET), 1);
        assertEq(manager.getTargetFunctionSelector(TARGET, 0), SEL_FOO);
        assertEq(manager.getTargetFunctionSelectorCount(targetB), 1);
        assertEq(manager.getTargetFunctionSelector(targetB, 0), SEL_BAR);
    }
}
