pragma solidity ^0.5.0;

contract StringAsKey {
  function convert(string memory key) public pure returns (bytes32 ret) {
    require(bytes(key).length > 32, "String cannot be converted into key as it is too long");

    assembly {
      ret := mload(add(key, 32))
    }
  }
}