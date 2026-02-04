// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    string public constant ASSERTION_INCREMENT_DOS = "!!! increment DoS";
    string public constant INVARIANT_NUMBER_IS_SMALL = "Invariant: number is small";

    function invariant_number_is_small() public returns (bool) {
        t(counter.number() < type(uint256).max / 2, INVARIANT_NUMBER_IS_SMALL);
        return true;
    }
}
