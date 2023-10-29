// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports from ERC20 contract from the OpenZepplin library.
// OpenZeppelin is a library for secure smart contract development. (audited)
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Contract is decelared with name: "Dotty" and inherits the ERC20 Contract.
contract BreadCoin is ERC20 {
    // constructor: executed during the creation of the contract,
    //  -> takes one parameter: initialSupply (specifies how many tokens are minted when contract is deployed.

    constructor(uint256 initialSupply) ERC20("BreadCoin", "BRDC") {
        // mints functions creates initialSupply amount of tokens
        // and is assigned to msg.sender (the address that deploys the contract)
        _mint(msg.sender, initialSupply);
    }
}