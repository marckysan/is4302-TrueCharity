const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
const BigNumber = require("bignumber.js");
const assert = require("assert");
const keccak256 = require("keccak256");

const oneEth = new BigNumber(1000000000000000000);

const CharityToken = artifacts.require("../contracts/CharityToken.sol");
const SuperApp = artifacts.require("../contracts/SuperApp.sol");
const Marketplace = artifacts.require("../contracts/Marketplace.sol");

/**
 * Account 0 : SuperApp owner
 * Account 1 : Marketplace owner
 * Accounts 2 - 5 : Test bidders
 */
contract("Marketplace", function (accounts) {
  before(async () => {
    charityTokenInstance = await CharityToken.deployed();
    superAppInstance = await SuperApp.deployed();
    marketplaceInstance = await Marketplace.deployed();
  });

  console.log("Testing Marketplace");

  // PRE BIDDING TEST CASES
  it("Get Category List", async () => {
    // Adding mock categories
    await superAppInstance.addCategory("Meat", { from: accounts[0] });
    await superAppInstance.addCategory("Furniture", { from: accounts[0] });
    await superAppInstance.addItem("Chicken", 1, "Meat", { from: accounts[0] });
    await superAppInstance.addItem("Pork", 2, "Meat", { from: accounts[0] });
    await superAppInstance.addItem("Table", 2, "Furniture", {
      from: accounts[0],
    });
    await superAppInstance.addItem("Chair", 1, "Furniture", {
      from: accounts[0],
    });
    await superAppInstance.transfer(accounts[1], { from: accounts[0] });

    let v1 = await marketplaceInstance.getCategories({
      from: accounts[1],
    });

    assert.equal(
      v1.logs[0].args.categoryList[0],
      "Meat",
      "Category lists generated do not match."
    );
    assert.equal(
      v1.logs[0].args.categoryList[1],
      "Furniture",
      "Category lists generated do not match."
    );
  });

  it("Get Category Min Bid when it's not set", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getCategoryMinBid("Meat", { from: accounts[1] }),
      "The category minimum bid has yet to be updated. Please wait, or update the minimum bids if you run the marketplace."
    );
  });

  it("Set Category Min Bid to Category Min Price as Unauthorized User [ownerOnly modifier]", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.setMinBidToMinPrice({ from: accounts[2] }),
      "Only the owner of the marketplace contract can call this function"
    );
  });

  it("Set Category Min Bid to Category Min Price", async () => {
    await marketplaceInstance.setMinBidToMinPrice({ from: accounts[1] });
    let v1 = await marketplaceInstance.getCategoryMinBid("Furniture", {
      from: accounts[2],
    });

    assert.equal(v1, 1, "Furniture Category Min Bid does not match.");
  });

  it("Set Category Min Bid to Specific Price as Marketplace Owner", async () => {
    await marketplaceInstance.setCategoryMinBid("Meat", 5, {
      from: accounts[1],
    });
    let v1 = await marketplaceInstance.getCategoryMinBid("Meat", {
      from: accounts[2],
    });
    assert.equal(v1, 5, "Meat Category Min Bid does not match.");
  });

  // SETTING MARKETPLACE STATUS TEST CASES
  it("Get marketplace status as the bidder", async () => {
    let v1 = await marketplaceInstance.getStatus({ from: accounts[2] });
    assert.equal(
      v1,
      Marketplace.MarketplaceState.closed,
      "Marketplace Status is wrong"
    );
  });

  it("Set marketplace status to open as the marketplace owner", async () => {
    await marketplaceInstance.start_bidding({ from: accounts[1] });
    let v1 = await marketplaceInstance.getStatus({ from: accounts[2] });
    assert.equal(
      v1,
      Marketplace.MarketplaceState.open,
      "Marketplace Status is wrong"
    );
  });

  // CHARITY TOKEN RELATED TEST CASES FOR BIDDERS
  it("Get Charity Token as marketplace owner", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getCT({
        from: accounts[1],
        value: oneEth.dividedBy(2),
      }),
      "Only the bidders can get, check and return Charity Tokens"
    );
  });

  it("Get Charity Token as bidders", async () => {
    await marketplaceInstance.getCT({
      from: accounts[2],
      value: oneEth.dividedBy(2),
    });

    await marketplaceInstance.getCT({
      from: accounts[3],
      value: oneEth,
    });

    const v1 = new BigNumber(
      await marketplaceInstance.checkCT({ from: accounts[2] })
    );
    const v2 = new BigNumber(
      await marketplaceInstance.checkCT({ from: accounts[3] })
    );

    correctCredits2 = new BigNumber(50);
    correctCredits3 = new BigNumber(100);

    await assert(
      v1.isEqualTo(correctCredits2),
      "Incorrect CT minted for account 2"
    );
    await assert(
      v2.isEqualTo(correctCredits3),
      "Incorrect CT minted for account 3"
    );
  });

  it("Return Charity Token as bidder who has no Charity Tokens", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.returnCT(oneEth.dividedBy(20000000000000000), {
        from: accounts[4],
      }),
      "You do not have sufficient Charity Tokens to return"
    );
  });

  it("Return Charity Token as bidder who has sufficient Charity Tokens", async () => {
    // Getting sufficient credits
    await marketplaceInstance.getCT({
      from: accounts[4],
      value: oneEth,
    });

    // Returning half of account 4's credits
    await marketplaceInstance.returnCT(oneEth.dividedBy(20000000000000000), {
      from: accounts[4],
    });

    let v1 = new BigNumber(
      await marketplaceInstance.checkCT({ from: accounts[4] })
    );

    correctCredits4 = new BigNumber(50);

    await assert(
      v1.isEqualTo(correctCredits4),
      "Incorrect CT balance after returning CT for account 4"
    );
  });
});
