// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./LibraryFactory.sol";

/**
 * @title MogSynthNFT
 * @notice An ERC721 NFT contract with phases (Locked, Presale, Whitelist, Public),
 * dynamic pricing, and an associated SoundLibrary deployed for each minted NFT.
 */
contract MogSynthNFT is ERC721, Pausable, Ownable(msg.sender), ReentrancyGuard {
    using Strings for uint256;

    /// @notice Enumeration of possible minting phases.
    enum Phase {
        Locked,
        Presale,
        Whitelist,
        Public
    }

    /// @notice The current minting phase.
    Phase public currentPhase = Phase.Locked;

    /// @notice The Merkle root used for whitelist verification.
    bytes32 public merkleRoot;

    /// @notice The base URI for NFT metadata.
    string private baseURI;

    /// @notice The price of the NFT during the presale phase.
    uint256 public presalePrice = 0.05 ether;
    /// @notice The price of the NFT during the whitelist phase.
    uint256 public whitelistPrice = 0.08 ether;
    /// @notice The price of the NFT during the public phase.
    uint256 public publicPrice = 0.1 ether;

    /// @notice The maximum number of NFTs that can be minted.
    uint256 public maxSupply = 10000;

    /// @notice The instance of the LibraryFactory contract used to create SoundLibraries.
    LibraryFactory public factory;

    /// @notice Mapping to track if an address has minted during the whitelist phase.
    mapping(address => bool) public whitelistMinted;

    /// @notice Mapping from tokenId to its associated SoundLibrary contract address.
    mapping(uint256 => address) private tokenIdToLibrary;

    /// @notice Counts how many tokens have been minted so far.
    uint256 private _totalMinted;

    /// @notice Emitted when the minting phase is changed.
    event PhaseChanged(Phase newPhase);

    /// @notice Emitted when the minting prices are changed.
    event PriceChanged(uint256 newPresalePrice, uint256 newWhitelistPrice, uint256 newPublicPrice);

    /// @notice Emitted when the base URI for metadata is changed.
    event BaseURIChanged(string newBaseURI);

    /**
     * @notice Constructor for MogSynthNFT.
     * @param _factory The address of the LibraryFactory contract.
     * @param _initBaseURI The initial base URI for NFT metadata.
     */
    constructor(address _factory, string memory _initBaseURI) ERC721("MogSynth", "MSYNTH") {
        factory = LibraryFactory(_factory);
        setBaseURI(_initBaseURI);
    }

    /**
     * @notice Ensures the contract is at the specified phase.
     */
    modifier atPhase(Phase phase) {
        require(currentPhase == phase, "Function cannot be called at this time.");
        _;
    }

    /**
     * @notice Returns the base URI for NFT metadata.
     * @return The current base URI string.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Sets a new base URI for NFT metadata.
     * @dev Only callable by the contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    /**
     * @notice Sets the Merkle root used for whitelist verification.
     * @dev Only callable by the contract owner.
     * @param _merkleRoot The new Merkle root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the prices for presale, whitelist, and public mint phases.
     * @dev Only callable by the contract owner.
     * @param _presalePrice The new presale price.
     * @param _whitelistPrice The new whitelist price.
     * @param _publicPrice The new public price.
     */
    function setPrices(uint256 _presalePrice, uint256 _whitelistPrice, uint256 _publicPrice) external onlyOwner {
        presalePrice = _presalePrice;
        whitelistPrice = _whitelistPrice;
        publicPrice = _publicPrice;
        emit PriceChanged(_presalePrice, _whitelistPrice, _publicPrice);
    }

    /**
     * @notice Pauses the contract, preventing minting and transfers.
     * @dev Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing minting and transfers.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the current minting phase.
     * @dev Only callable by the contract owner.
     * @param _phase The new phase to transition to.
     */
    function setPhase(Phase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }

    /**
     * @notice Mints a new NFT during the allowed phases.
     * @dev Uses different pricing and verification depending on the current phase.
     * Deploys a SoundLibrary contract for each minted NFT.
     * @param _merkleProof An array of Merkle proofs if minting in the Whitelist phase.
     */
    function mint(bytes32[] calldata _merkleProof) external payable whenNotPaused nonReentrant {
        require(_totalMinted < maxSupply, "Max supply reached");

        if (currentPhase == Phase.Presale) {
            require(msg.value >= presalePrice, "Insufficient Ether sent for presale");
        } else if (currentPhase == Phase.Whitelist) {
            require(msg.value >= whitelistPrice, "Insufficient Ether sent for whitelist");
            require(!whitelistMinted[msg.sender], "Already minted in whitelist");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");
            whitelistMinted[msg.sender] = true;
        } else if (currentPhase == Phase.Public) {
            require(msg.value >= publicPrice, "Insufficient Ether sent for public mint");
        } else {
            revert("Minting is locked");
        }

        uint256 tokenId = _totalMinted;
        _totalMinted += 1;

        _safeMint(msg.sender, tokenId);

        // Deploy a SoundLibrary for the newly minted token
        address libraryAddress = factory.createLibrary(msg.sender, 16, 100);

        // Store the library address associated with this tokenId
        tokenIdToLibrary[tokenId] = libraryAddress;
    }

    /**
     * @notice Withdraws all Ether from the contract to the owner's address.
     * @dev Only callable by the contract owner.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @notice Returns the SoundLibrary contract address associated with a given tokenId.
     * @param tokenId The ID of the token to query.
     * @return The address of the associated SoundLibrary contract.
     */
    function getSoundLibraryAddress(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Query for nonexistent token");
        return tokenIdToLibrary[tokenId];
    }

    /**
     * @notice Custom implementation of _exists function since we are not relying on ERC721Enumerable for enumeration.
     * @dev Returns true if token with the given tokenId has been minted.
     * @param tokenId The token ID to check.
     * @return True if the token exists, false otherwise.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _totalMinted;
    }


    /**
     * @notice Returns the total number of tokens minted so far.
     * @return The total minted supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalMinted;
    }

    /**
     * @notice Fallback function to accept Ether.
     */
    receive() external payable {}

    /**
     * @notice Fallback function to accept data with Ether.
     */
    fallback() external payable {}
}
