// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    string public constant ASSERTION_INCREMENT_DOS = "!!! increment DoS";
    string public constant INVARIANT_NUMBER_IS_SMALL = "Invariant: number is small";
    string public constant INVARIANT_NUMBER_CHANGE_REQUIRES_SEQUENCE = "Invariant: number change requires sequence";

    function invariant_number_is_small() public returns (bool) {
        t(counter.number() < type(uint256).max / 2, INVARIANT_NUMBER_IS_SMALL);
        return true;
    }

    function invariant_number_change_requires_sequence() public returns (bool) {
        t(!(_before.number == 2 && _after.number == 3), INVARIANT_NUMBER_CHANGE_REQUIRES_SEQUENCE);
        return true;
    }
}
