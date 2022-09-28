import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployAuctionFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, address1, address2] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory("Auction");
    const auction = await Auction.deploy(owner.address);

    return { auction, owner, address1, address2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);

      expect(await auction.owner()).to.equal(owner.address);
    });
  });

  describe("Methods", () => {
    it("Should revert due atherAccount change auction state to CANCEL", async () => {
      const { auction, address1 } = await loadFixture(deployAuctionFixture);
      await expect(auction.connect(address1).cancelAuction()).to.be.reverted;
      expect(await auction.connect(address1).auctionState()).to.equal(1);
    });

    it("Should change auction state to CANCEL and emit a event", async () => {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      expect(await auction.cancelAuction()).to.emit(auction, "CancelEvent").withArgs(owner.address);
      expect(await auction.auctionState()).to.equal(3);
    });
  });

  describe("Auction", () => {
    it("Should place a bid one user different from owner", async () => {
      const { auction, address1 } = await loadFixture(deployAuctionFixture);
      await auction.connect(address1).placeBid({ value: "1000000000000000000" });
      expect(await auction.highestBindingBid()).to.equal("1000000000000000000");
    });

    it("Should revert due owner is trying to place a bid", async () => {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      await expect(auction.placeBid({ value: "1000000000000000000" })).to.be.reverted;
    });
  });

});
