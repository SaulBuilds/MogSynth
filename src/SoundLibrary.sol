// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract SoundLibrary is ReentrancyGuard {
    struct Sound {
        bytes data;
        address[] contributors;
    }

    Sound[] public sounds;
    address public owner;
    uint8 public bitDepth;
    uint256 public maxSamples;

    mapping(address => bool) public collaborators;

    // Events
    event SoundAdded(uint256 indexed soundId, address indexed contributor);
    event CollaboratorAdded(address indexed collaborator);
    event CollaboratorRemoved(address indexed collaborator);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyCollaborator() {
        require(collaborators[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _owner, uint8 _bitDepth, uint256 _maxSamples) {
        owner = _owner;
        bitDepth = _bitDepth;
        maxSamples = _maxSamples;
    }

    function addCollaborator(address _collaborator) external onlyOwner {
        collaborators[_collaborator] = true;
        emit CollaboratorAdded(_collaborator);
    }

    function removeCollaborator(address _collaborator) external onlyOwner {
        collaborators[_collaborator] = false;
        emit CollaboratorRemoved(_collaborator);
    }

    function addSound(bytes memory data) external onlyCollaborator nonReentrant {
        require(sounds.length < maxSamples, "Max samples reached");

        // Effects
        Sound storage newSound = sounds.push();
        newSound.data = data;
        newSound.contributors.push(msg.sender);

        // Interactions
        emit SoundAdded(sounds.length - 1, msg.sender);
    }

    function getSound(uint256 index) external view returns (bytes memory) {
        require(index < sounds.length, "Sound does not exist");
        return sounds[index].data;
    }

    function getContributors(uint256 index) external view returns (address[] memory) {
        require(index < sounds.length, "Sound does not exist");
        return sounds[index].contributors;
    }
}
