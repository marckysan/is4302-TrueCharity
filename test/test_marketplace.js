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
  it("Get Items List (Not Marketplace Owner)", async () => {
    // Adding mock categories
    await superAppInstance.addItem("Chicken", 1);
    await superAppInstance.addItem("Cloth", 3);
    await superAppInstance.addItem("Chair", 2);
    await superAppInstance.addItem("Shirt", 5);
    await superAppInstance.addItem("Milo", 2);
    await truffleAssert.reverts(
      marketplaceInstance.getAllAvailableItemsAndPrices({ from: accounts[2] }),
      "Only the owner of the marketplace contract can call this function"
    );
  });

  it("Get Item List (Superapp not transferred yet)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getAllAvailableItemsAndPrices({
        from: accounts[1],
      }),
      "SuperApp store ownership has yet to be transferred."
    );
  });

  it("Get Items List", async () => {
    await superAppInstance.transfer(accounts[1], { from: accounts[0] });
    let v1 = await marketplaceInstance.getAllAvailableItemsAndPrices({
      from: accounts[1],
    });

    truffleAssert.eventEmitted(
      v1,
      "allItemsRetrieved",
      (args) => {
        return (
          args.itemsList[0] == "Chicken" &&
          args.itemsList[1] == "Cloth" &&
          args.itemsList[2] == "Chair" &&
          args.itemsList[3] == "Shirt" &&
          args.itemsList[4] == "Milo"
        );
      },
      "The item list generated was incorrect."
    );
    truffleAssert.eventEmitted(
      v1,
      "allItemsPricesRetrieved",
      (args) => {
        return (
          args.prices[0] == 1 &&
          args.prices[1] == 3 &&
          args.prices[2] == 2 &&
          args.prices[3] == 5 &&
          args.prices[4] == 2
        );
      },
      "The price list generated was incorrect."
    );
  });

  it("Set Required Items and Prices and Quota based on Store Prices (Different input lengths)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.setRequiredItemsInfo(["Chicken", "Chair"], [10], {
        from: accounts[1],
      }),
      "The number of required items in the required items list and required items quota do not match."
    );
  });

  it("Set Required Items and Prices and Quota based on Store Prices (Invalid Item)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.setRequiredItemsInfo(["Chicken", "Table"], [10, 5], {
        from: accounts[1],
      }),
      "THe following item does not exist: Table"
    );
  });

  it("Set Required Items and Prices and Quota based on Store Prices", async () => {
    let v1 = await marketplaceInstance.setRequiredItemsInfo(
      ["Chicken", "Chair"],
      [10, 5],
      {
        from: accounts[1],
      }
    );
    truffleAssert.eventEmitted(
      v1,
      "itemsRequiredSet",
      (args) => {
        return (
          args.requiredItemsList[0] == "Chicken" &&
          args.requiredItemsList[1] == "Chair"
        );
      },
      "The required items list generated was incorrect."
    );
  });

  it("Set Required Items and Prices and Quota Manually (Different input lengths)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.setRequiredItemsInfoManual(
        ["Chicken", "Chair"],
        [10, 5],
        [2],
        {
          from: accounts[1],
        }
      ),
      "The number of required items in the required items list and required items quota and required items prices do not match."
    );
  });

  it("Set Required Items and Prices and Quota based on Store Prices", async () => {
    let v1 = await marketplaceInstance.setRequiredItemsInfoManual(
      ["Cloth", "Milo"],
      [10, 5],
      [1, 2],
      {
        from: accounts[1],
      }
    );
    truffleAssert.eventEmitted(
      v1,
      "itemsRequiredSet",
      (args) => {
        return (
          args.requiredItemsList[0] == "Cloth" &&
          args.requiredItemsList[1] == "Milo"
        );
      },
      "The required items list generated was incorrect."
    );
  });

  it("Update Item Quota (Invalid Item)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.updateItemQuota("Chicken Rice", 10, {
        from: accounts[1],
      }),
      "THe item has not been added into the required item list."
    );
  });

  it("Update Item Quota (Old and new quota same)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.updateItemQuota("Chicken", 10, {
        from: accounts[1],
      }),
      "The old and new quota should not be the same"
    );
  });

  it("Update Item Quota", async () => {
    let v1 = await marketplaceInstance.updateItemQuota("Chicken", 20, {
      from: accounts[1],
    });
    truffleAssert.eventEmitted(
      v1,
      "itemQuotaUpdated",
      (args) => {
        return args.itemName == "Chicken" && args.quota == 20;
      },
      "The item or quota to be updated was incorrect."
    );
  });

  it("Update Item Min Donation (Invalid Item)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.updateItemMinDonation("Chicken Rice", 4, {
        from: accounts[1],
      }),
      "THe item has not been added into the required item list."
    );
  });

  it("Update Item Min Donation (Old and new quota same)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.updateItemMinDonation("Chicken", 1, {
        from: accounts[1],
      }),
      "The old and new min donation should not be the same"
    );
  });

  it("Update Item Min Donation", async () => {
    let v1 = await marketplaceInstance.updateItemMinDonation("Chicken", 6, {
      from: accounts[1],
    });
    truffleAssert.eventEmitted(
      v1,
      "itemMinDonationUpdated",
      (args) => {
        return args.itemName == "Chicken" && args.minDonation == 6;
      },
      "The item or min donation to be updated was incorrect."
    );
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

  it("Get Donatable Items Options", async () => {
    let v1 = await marketplaceInstance.getDonatableItemOptions({
      from: accounts[2],
    });
    assert.equal(v1[0], "Cloth", "Donatable Items List is wrong");
    assert.equal(v1[1], "Milo", "Donatable Items List is wrong");
  });

  it("Get Item Per Unit Donation Amount (Item don't exist)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getItemPerUnitDonationAmount("Cheese", {
        from: accounts[2],
      }),
      "Item does not exist."
    );
  });

  it("Get Item Per Unit Donation Amount", async () => {
    let v1 = await marketplaceInstance.getItemPerUnitDonationAmount("Milo", {
      from: accounts[2],
    });

    assert.equal(v1, 2, "Per Unit Donation Amount is wrong");
  });

  it("Get Item Remaining Quota (Item don't exist)", async () => {
    await truffleAssert.reverts(
      marketplaceInstance.getNumDonorsToQuota("Cheese", {
        from: accounts[2],
      }),
      "Item is not needed in this charity drive or item does not exist."
    );
  });

  it("Get Item Remaining Quota", async () => {
    let v1 = await marketplaceInstance.getNumDonorsToQuota("Cloth", {
      from: accounts[2],
    });

    assert.equal(v1, 10, "Number of donors to hit quota is wrong");
  });

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
