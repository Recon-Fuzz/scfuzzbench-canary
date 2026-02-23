// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
        targetSender(address(0x10000));
        targetSender(address(0x20000));
        targetSender(address(0x30000));
    }

    // Dedicated campaign to surface handler-level assertion failures from `counter_increment`.
    function invariant_counter_increment() public pure {}
}
