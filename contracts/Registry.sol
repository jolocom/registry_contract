pragma solidity ^0.5.1;

contract Registry {
    event Updated (
        bytes32 did,
        uint timestamp
    );

    struct Record {
        bytes owner;
        bytes recovery;
        string servicesHash;
    }

    mapping(bytes32 => Record) private didRegistry;

    modifier onlyOwnerWithoutRecovery(bytes32 did) {
        address ownerAddress = pubKeyToAddress(didRegistry[did].owner);
        if (msg.sender != ownerAddress)
            revert("Sender is not authorized.");
        if (didRegistry[did].recovery.length != 0)
            revert("Recovery can not be changed.");
        _;
    }

    function setIdentity(bytes32 did, bytes memory owner, string memory servicesHash) public {
        address ownerAddress = pubKeyToAddress(didRegistry[did].owner);
        address recoveryAddress = pubKeyToAddress(didRegistry[did].recovery);
        emit Updated(did, now);
        if (ownerAddress != address(0)) {
            if (msg.sender != recoveryAddress && msg.sender != ownerAddress) {
                revert("Sender is not authorized.");
            }
        }
        if (msg.sender == recoveryAddress) {
            didRegistry[did] = Record(owner, "", servicesHash);
        } else {
            didRegistry[did] = Record(owner, didRegistry[did].recovery, servicesHash);
        }
    }

    function setRecovery(bytes32 did, bytes memory recovery) public onlyOwnerWithoutRecovery(did) {
        Record storage record = didRegistry[did];
        record.recovery = recovery;
    }

    function getIdentity(bytes32 did) public view returns (bytes memory, bytes memory, string memory) {
        return (didRegistry[did].owner, didRegistry[did].recovery, didRegistry[did].servicesHash);
    }

    function pubKeyToAddress(bytes memory publicKey) internal pure returns (address) {
        if (publicKey.length == 0)
            return address(0);
        require (publicKey.length == 64, "public key must have 64 bytes");
        return address(bytes20(uint160(uint256(keccak256(publicKey)))));
    }

}
