// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        uint256 number;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts() {
        __before();
        _;
        __after();
    }

    function __before() internal {
        __snapshot(_before);
    }

    function __after() internal {
        __snapshot(_after);
    }

    function __snapshot(Vars storage state) internal {
        state.number = counter.number();
    }
}
