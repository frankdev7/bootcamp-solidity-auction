//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Auction {
    address public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {
        Started,
        Running,
        Ended,
        Canceled
    }
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;

    //the owner can finalize the auction and get the highestBindingBid only once
    bool public ownerFinalized = false;

    constructor(address _owner) {
        owner = _owner;
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 3;
        ipfsHash = "";
        bidIncrement = 1 ether;
    }

    // declaring function modifiers
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    // Events
    event CancelEvent(address);

    //a helper pure function (it neither reads, nor it writes to the blockchain)
    function min(uint a, uint b) internal pure returns (uint) {
        return a <= b ? a : b;
    }

    // only the owner can cancel the Auction before the Auction has ended
    function cancelAuction() public beforeEnd onlyOwner {
        auctionState = State.Canceled;
        emit CancelEvent(msg.sender);
    }

    // the main function called to place a bid
    function placeBid()
        public
        payable
        notOwner
        afterStart
        beforeEnd
        returns (bool)
    {
        // to place a bid auction should be running
        require(auctionState == State.Running);
        // minimum value allowed to be sent
        // require(msg.value > 0.0001 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        // the currentBid should be greater than the highestBindingBid.
        // Otherwise there's nothing to do.
        require(
            currentBid > highestBindingBid,
            "Your bid should be greater than highest bid"
        );

        // updating the mapping variable
        bids[msg.sender] = currentBid;

        highestBindingBid = currentBid;
        highestBidder = payable(msg.sender);
        return true;
    }

    function finalizeAuction() public {
        // the auction has been Canceled or Ended
        require(auctionState == State.Canceled || block.number > endBlock);

        // only the owner or a bidder can finalize the auction
        require(msg.sender == owner || bids[msg.sender] > 0);

        // the recipient will get the value
        address payable recipient;
        uint value;

        if (auctionState == State.Canceled) {
            // auction canceled, not ended
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // auction ended, not canceled
            if (msg.sender == owner && ownerFinalized == false) {
                //the owner finalizes the auction
                recipient = payable(owner);
                value = highestBindingBid;

                //the owner can finalize the auction and get the highestBindingBid only once
                ownerFinalized = true;
            } else {
                // another user (not the owner) finalizes the auction
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    //this is neither the owner nor the highest bidder (it's a regular bidder)
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // resetting the bids of the recipient to avoid multiple transfers to the same recipient
        bids[recipient] = 0;

        //sends value to the recipient
        recipient.transfer(value);
    }
}
