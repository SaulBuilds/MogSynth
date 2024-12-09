// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./SoundLibrary.sol";

/**
 * @title LibraryFactory
 * @dev Factory contract to create and manage SoundLibrary contracts.
 */
contract LibraryFactory is Ownable(msg.sender) {
    // Array to store all SoundLibrary addresses
    SoundLibrary[] private soundLibraries;

    // Event emitted when a new SoundLibrary is created
    event LibraryCreated(address indexed libraryAddress, address indexed owner, uint8 bitDepth, uint256 maxSamples);

    /**
     * @dev Creates a new SoundLibrary contract and stores its address.
     * Can be restricted to onlyOwner if desired.
     * @param _owner The owner of the new SoundLibrary.
     * @param bitDepth The bit depth of the SoundLibrary (e.g., 8 or 16).
     * @param maxSamples The maximum number of sound samples the library can hold.
     * @return The address of the newly created SoundLibrary.
     */
    function createLibrary(address _owner, uint8 bitDepth, uint256 maxSamples) external onlyOwner returns (address) {
        SoundLibrary newLibrary = new SoundLibrary(_owner, bitDepth, maxSamples);
        soundLibraries.push(newLibrary);
        emit LibraryCreated(address(newLibrary), _owner, bitDepth, maxSamples);
        return address(newLibrary);
    }

    /**
     * @dev Returns the total number of SoundLibraries created.
     * @return The count of SoundLibrary contracts.
     */
    function getTotalLibraries() external view returns (uint256) {
        return soundLibraries.length;
    }

    /**
     * @dev Retrieves the SoundLibrary address at a specific index.
     * @param index The index in the soundLibraries array.
     * @return The address of the SoundLibrary at the given index.
     */
    function getLibraryByIndex(uint256 index) external view returns (address) {
        require(index < soundLibraries.length, "Index out of bounds");
        return address(soundLibraries[index]);
    }

    /**
     * @dev Retrieves all SoundLibrary addresses.
     * @return An array of SoundLibrary contract addresses.
     */
    function getAllLibraries() external view returns (address[] memory) {
        address[] memory libraries = new address[](soundLibraries.length);
        for (uint256 i = 0; i < soundLibraries.length; i++) {
            libraries[i] = address(soundLibraries[i]);
        }
        return libraries;
    }
}
