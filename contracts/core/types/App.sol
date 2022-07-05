// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "./ProtoBufRuntime.sol";
import "./GoogleProtobufAny.sol";

library FungibleTokenPacketData {


  //struct definition
  struct Data {
    string denom;
    uint64 amount;
    string sender;
    string receiver;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(0, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(0, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param pos The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 pos, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    require(sz > 0);
    require(bs[0] == 0x7b /* { */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    pos = _parse_amount(pos, bs, r);
    require(bs[pos] == 0x2C /* , */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    pos = _parse_denom(pos, bs, r);
    require(bs[pos] == 0x2C /* , */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    pos = _parse_receiver(pos, bs, r);
    require(bs[pos] == 0x2C /* , */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    pos = _parse_sender(pos, bs, r);
    pos = _skip_whitespace(pos, bs);
    require(bs[pos] == 0x7D /* } */);
    return (r, sz);
  }

  function _skip_whitespace(uint256 pos, bytes memory bs)
      internal
      pure
      returns (uint256)
  {
      for (; pos < bs.length; pos += 1) {
          // ' ', ¥t, ¥t, ¥n
          if (bs[pos] == 0x20 || bs[pos] == 0x12 || bs[pos] == 0x14 || bs[pos] == 0x1A) {}
          else break;
      }
      return pos;
  }

  function _parse_amount(
                         uint256 pos,
                         bytes memory bs,
                         Data memory r)
      internal
      pure
      returns (uint256)
  {
      require(bs[pos] == 0x22 /* " */);
      pos += 1;
      require(bs[pos] == 0x41 || bs[pos] == 0x61); // A or a
      pos += 1;
      require(bs[pos] == 0x4D || bs[pos] == 0x6D); // M or m
      pos += 1;
      require(bs[pos] == 0x4F || bs[pos] == 0x6F); // O or o
      pos += 1;
      require(bs[pos] == 0x55 || bs[pos] == 0x75); // U or u
      pos += 1;
      require(bs[pos] == 0x4E || bs[pos] == 0x6E); // N or n
      pos += 1;
      require(bs[pos] == 0x54 || bs[pos] == 0x74); // T or t
      pos += 1;
      require(bs[pos] == 0x22 /* " */);
      pos += 1;
      require(bs[pos] == 0x3A /* : */);
      pos += 1;
      pos = _skip_whitespace(pos, bs);
      uint64 amount;
      for (; pos < bs.length; pos += 1) {
          // 0-9
          if (bs[pos] >= 0x30 && bs[pos] <= 0x39) {
              amount = uint64(amount * 10 + (uint64(uint8(bs[pos])) - uint64(0x30)));
          }
          else break;
      }
      r.amount = amount;
      return pos;
  }

  function _parse_denom(
                        uint256 pos,
                        bytes memory bs,
                        Data memory r
                        )
      internal
      pure
      returns (uint256)
  {
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x44 || bs[pos] == 0x64); // D or d
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x4E || bs[pos] == 0x6E); // N or n
    pos += 1;
    require(bs[pos] == 0x4F || bs[pos] == 0x6F); // O or o
    pos += 1;
    require(bs[pos] == 0x4D || bs[pos] == 0x6D); // M or m
    pos += 1;
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x3A /* : */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    require(bs[pos] == 0x22 /* " */);
    pos += 1;

    uint256 oldPos = pos;
    for (; pos < bs.length; pos += 1) {
        // 0-9
        if (bs[pos] >= 0x30 && bs[pos] <= 0x39) {
        }
        // A-Z
        else if (bs[pos] >= 0x41 && bs[pos] <= 0x5A) {
        }
        // a-z
        else if (bs[pos] >= 0x61 && bs[pos] <= 0x7A) {
        }
        // https://github.com/cosmos/ibc/tree/main/spec/core/ics-024-host-requirements#paths-identifiers-separators
        else if (bs[pos] == 0x23 /* # */ ||
                 bs[pos] == 0x2B /* + */ ||
                 bs[pos] == 0x2D /* - */ ||
                 bs[pos] == 0x2E /* . */ ||
                 bs[pos] == 0x2F /* / */ ||
                 bs[pos] == 0x3C /* < */ ||
                 bs[pos] == 0x3E /* > */ ||
                 bs[pos] == 0x5B /* [ */ ||
                 bs[pos] == 0x5D /* ] */ ||
                 bs[pos] == 0x5F /* _ */) {
        }
        else break;
    }

    uint256 len = pos - oldPos;
    uint256 src;
    uint256 dest;
    bytes memory denom = new bytes(len);
    uint256 tmp = oldPos + 32;
    assembly {
        dest := add(denom, 32)
        src := add(bs, tmp)
    }

    /* memcpy(dest, src, len); */
    uint i = 0;
    for (; i < len; i += 1) {
        assembly {
            mstore(dest, mload(src))
        }
        dest += 1;
        src += 1;
    }

    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    r.denom = string(denom);
    return pos;
  }

  function _parse_receiver(
                           uint256 pos,
                           bytes memory bs,
                           Data memory r)
      internal
      pure
      returns (uint)
  {
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x52 || bs[pos] == 0x72); // R or r
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x43 || bs[pos] == 0x63); // C or c
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x49 || bs[pos] == 0x69); // I or i
    pos += 1;
    require(bs[pos] == 0x56 || bs[pos] == 0x76); // V or v
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x52 || bs[pos] == 0x72); // R or r
    pos += 1;
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x3A /* : */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    require(bs[pos] == 0x22 /* " */);
    pos += 1;

    uint256 oldPos = pos;
    for (; pos < bs.length; pos += 1) {
        // 0-9
        if (bs[pos] >= 0x30 && bs[pos] <= 0x39) {
        }
        // A-Z
        else if (bs[pos] >= 0x41 && bs[pos] <= 0x5A) {
        }
        // a-z
        else if (bs[pos] >= 0x61 && bs[pos] <= 0x7A) {
        }
        else break;
    }
    uint256 len = pos - oldPos;
    uint256 src;
    uint256 dest;
    bytes memory receiver = new bytes(len);
    uint256 tmp = oldPos + 32;
    assembly {
        dest := add(receiver, 32)
        src := add(bs, tmp)
    }

    /* memcpy(dest, src, len); */
    uint i = 0;
    for (; i < len; i += 1) {
        assembly {
            mstore(dest, mload(src))
        }
        dest += 1;
        src += 1;
    }

    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    r.receiver = string(receiver);
    return pos;
  }

  function _parse_sender(
                         uint256 pos,
                         bytes memory bs,
                         Data memory r)
      internal
      pure
      returns (uint256)
  {
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x53 || bs[pos] == 0x73); // S or s
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x4E || bs[pos] == 0x6E); // N or n
    pos += 1;
    require(bs[pos] == 0x44 || bs[pos] == 0x64); // D or d
    pos += 1;
    require(bs[pos] == 0x45 || bs[pos] == 0x65); // E or e
    pos += 1;
    require(bs[pos] == 0x52 || bs[pos] == 0x72); // R or r
    pos += 1;
    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    require(bs[pos] == 0x3A /* : */);
    pos += 1;
    pos = _skip_whitespace(pos, bs);
    require(bs[pos] == 0x22 /* " */);
    pos += 1;

    uint256 oldPos = pos;
    for (; pos < bs.length; pos += 1) {
        // 0-9
        if (bs[pos] >= 0x30 && bs[pos] <= 0x39) {
        }
        // A-Z
        else if (bs[pos] >= 0x41 && bs[pos] <= 0x5A) {
        }
        // a-z
        else if (bs[pos] >= 0x61 && bs[pos] <= 0x7A) {
        }
        else break;
    }
    uint256 len = pos - oldPos;
    uint256 src;
    uint256 dest;
    uint256 tmp = oldPos + 32;
    bytes memory sender = new bytes(len);
    assembly {
        dest := add(sender, 32)
        src := add(bs, tmp)
    }

    /* memcpy(dest, src, len); */
    uint i = 0;
    for (; i < len; i += 1) {
        assembly {
            mstore(dest, mload(src))
        }
        dest += 1;
        src += 1;
    }

    require(bs[pos] == 0x22 /* " */);
    pos += 1;
    r.sender = string(sender);
    return pos;
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_denom(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    r.denom = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_amount(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
    r.amount = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_sender(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    r.sender = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_receiver(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    r.receiver = x;
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    /* bytes memory bs = new bytes(_estimate(r)); */
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
      uint256 temp = r.amount;
      uint256 digits;
      while (temp != 0) {
          digits++;
          temp /= 10;
      }

      uint256 len = 1 /* { */ + 8 /* "amount" */ + 1 /* : */  + digits + 1 /* , */  +
          7 /* "denom" */ + 1 /* : */ + 1 /* " */ + bytes(r.denom).length + 1 /* " */ + 1 /* ,*/  +
          10 /* "receiver" */ + 1 /* : */ + 1 /* " */ + bytes(r.receiver).length + 1 /* " */ + 1 /* , */  +
          8 /* "sender" */ + 1 /* : */ + 1 /* " */ + bytes(r.sender).length + 1 /* " */ + 1 /* } */;

      bytes memory bs = new bytes(len);
      (bytes memory x, uint256 _size) = _encode(r, 0, bs, digits);
      return x;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs, uint256 digits)
    internal
    pure
      returns (bytes memory, uint)
  {
      bytes memory s = new bytes(digits);
      uint256 value = r.amount;
      while (value != 0) {
          digits -= 1;
          s[digits] = bytes1(uint8(48 + uint256(value % 10)));
          value /= 10;
      }

      bytes memory x = abi.encodePacked(
                            "{\"amount\":", string(s),
                            ",\"denom\":\"", r.denom,
                            "\",\"receiver\":\"", r.receiver,
                            "\",\"sender\":\"", r.sender,
                            "\"}");
      return (x, p + x.length);
/*
    uint256 offset = p;
    uint256 pointer = p;

    if (bytes(r.denom).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.denom, pointer, bs);
    }
    if (r.amount != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_uint64(r.amount, pointer, bs);
    }
    if (bytes(r.sender).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.sender, pointer, bs);
    }
    if (bytes(r.receiver).length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.receiver, pointer, bs);
    }
    return pointer - offset;
*/
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    (bytes memory _bs, uint256 size) = _encode(r, 32, tmp, 0);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.denom).length);
    e += 1 + ProtoBufRuntime._sz_uint64(r.amount);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.sender).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.receiver).length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (bytes(r.denom).length != 0) {
    return false;
  }

  if (r.amount != 0) {
    return false;
  }

  if (bytes(r.sender).length != 0) {
    return false;
  }

  if (bytes(r.receiver).length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.denom = input.denom;
    output.amount = input.amount;
    output.sender = input.sender;
    output.receiver = input.receiver;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library FungibleTokenPacketData
