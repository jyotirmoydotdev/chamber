// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - Authorizes current contract to perform actions to itself.
contract SelfAuthorized {
    function requireSelfCall() private view{
        require (msg.sender == address(this), "Method can only be called form this contract");
    }
    modifier authorized {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}