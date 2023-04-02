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

    let v1 = await marketplaceInstance.getCategories({ from: accounts[1] });

    // TODO: need to figure out how to assert on array
    // assert.equal(
    //   keccak256(v1.rawLogs),
    //   ["Meat", "Furniture"],
    //   "Category lists generated do not match."
    // );
  });

  it("Get Category Min Bid when it's not set", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getCategoryMinBid("Meat", { from: accounts[1] }),
      "The category minimum bid has yet to be updated. Please wait, or update the minimum bids if you run the marketplace."
    );
  });

  it("Set Category Min Bid to Category Min Price", async () => {
    await marketplaceInstance.setMinBidToMinPrice({ from: accounts[1] });
    let v1 = marketplaceInstance.getCategoryMinBid("Furniture", {
      from: accounts[2],
    });

    assert.equal(v1, 1, "Furniture Category Min Bid does not match.");
  });
});
