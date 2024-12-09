// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/LibraryFactory.sol";
import "../src/MogSynth.sol";

/**
 * @title Deploy
 * @notice A Foundry script to deploy LibraryFactory and MogSynthNFT.
 */
contract Deploy is Script {
    function run() external {
        // Load private key from environment variable or set in code for local testing
        // For local anvil testing, you can use the default Anvil private keys or set ETH_FROM
        // In a production or CI environment, use environment variables:
        // e.g. export PRIVATE_KEY=0xabc123...
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the LibraryFactory contract
        LibraryFactory factory = new LibraryFactory();

        // Set a base URI for the NFTs
        string memory baseURI = "https://example.com/api/metadata/";

        // Deploy the MogSynthNFT contract, passing the factory address and baseURI
        MogSynthNFT mogSynth = new MogSynthNFT(address(factory), baseURI);

        vm.stopBroadcast();

        // Print addresses for verification
        console.log("LibraryFactory deployed at:", address(factory));
        console.log("MogSynthNFT deployed at:", address(mogSynth));
    }
}
