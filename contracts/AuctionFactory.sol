//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Auction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// this contract will deploy the Auction contract
contract AuctionFactory is Ownable {
    // declaring a dynamic array with addresses of deployed contracts
    Auction[] public auctions;

    // declaring the function that will deploy contract Auction
    function createAuction() public {
        // passing msg.sender to the constructor of Auction
        Auction newAuction = new Auction(owner());
        auctions.push(newAuction); // adding the address of the instance to the dynamic array
    }
}
