// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../../../contracts/core/types/App.sol";

contract FungibleTokenPacketDataTest is Test {

    /* test cases */

    function testDecodeFungibleTokenPacketData() public {
        bytes memory data = bytes("{\"amount\":100,\"denom\":\"100\",\"receiver\":\"0x11\",\"sender\":\"0x11\"}");
        FungibleTokenPacketData.Data memory r = FungibleTokenPacketData.decode(data);
        assertEq(r.amount, 100);
        assertEq(r.denom, "100");
        assertEq(r.receiver, "0x11");
        assertEq(r.sender, "0x11");
    }

    function testEncodeFungibleTokenPacketData() public {
        FungibleTokenPacketData.Data memory data = FungibleTokenPacketData.Data("200", 100, "0x333", "0x444");
        bytes memory arr = FungibleTokenPacketData.encode(data);
        assertEq(arr,  bytes("{\"amount\":100,\"denom\":\"200\",\"receiver\":\"0x444\",\"sender\":\"0x333\"}"));
    }

    function testEncodeAndDecodeFungibleTokenPacketData() public {
        FungibleTokenPacketData.Data memory data = FungibleTokenPacketData.Data("200", 100, "0x333", "0x444");
        bytes memory arr = FungibleTokenPacketData.encode(data);
        assertEq(arr,  bytes("{\"amount\":100,\"denom\":\"200\",\"receiver\":\"0x444\",\"sender\":\"0x333\"}"));

        FungibleTokenPacketData.Data memory r = FungibleTokenPacketData.decode(arr);
        assertEq(r.amount, 100);
        assertEq(r.denom, "200");
        assertEq(r.receiver, "0x444");
        assertEq(r.sender, "0x333");
    }
}
