const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
const BigNumber = require("bignumber.js");
const assert = require("assert");

const oneEth = new BigNumber(1000000000000000000);

const CharityToken = artifacts.require("../contracts/CharityToken.sol");
const SuperApp = artifacts.require("../contracts/SuperApp.sol");

contract("SuperApp", function (accounts) {
  before(async () => {
    charityTokenInstance = await CharityToken.deployed();
    superAppInstance = await SuperApp.deployed();
  });

  console.log("Testing SuperApp");

  it("Add Item (Not Owner)", async () => {
    truffleAssert.reverts(
      superAppInstance.addItem("Chicken", 2, { from: accounts[1] }),
      "Only the owner of the superapp contract can call this function"
    );
  });

  it("Add Item (0 Price)", async () => {
    truffleAssert.reverts(
      superAppInstance.addItem("Chicken", 0, { from: accounts[0] }),
      "Item's min price needs to be more than 0 Charity Token"
    );
  });

  it("Add Item", async () => {
    let v1 = await superAppInstance.addItem("Chicken", 1);
    truffleAssert.eventEmitted(
      v1,
      "itemAdded",
      (args) => {
        return args.addedItem == "Chicken";
      },
      "The item added was incorrect."
    );
  });

  it("Add Item (Duplicate item)", async () => {
    await truffleAssert.reverts(
      superAppInstance.addItem("Chicken", 1),
      "Item already exists, please update the item instead"
    );
  });

  it("Update Item Name (Don't exist)", async () => {
    await truffleAssert.reverts(
      superAppInstance.updateItemName("Drinks", "Wheat"),
      "Item does not exist"
    );
  });

  it("Update Item Name (New name already used)", async () => {
    await superAppInstance.addItem("Rice", 2);

    await truffleAssert.reverts(
      superAppInstance.updateItemName("Chicken", "Rice"),
      "The new name is already used"
    );
  });

  it("Update Item Name", async () => {
    let v1 = await superAppInstance.updateItemName("Rice", "Chair");

    truffleAssert.eventEmitted(
      v1,
      "itemNameUpdated",
      (args) => {
        return args.oldItem == "Rice" && args.newItem == "Chair";
      },
      "The item name was not updated correctly"
    );
  });

  it("Update Item Price (0 Price)", async () => {
    truffleAssert.reverts(
      superAppInstance.updateItemPrice("Chicken", 0, { from: accounts[0] }),
      "New price must be more than 0 Charity Token"
    );
  });

  it("Update Item Price (Don't exist)", async () => {
    truffleAssert.reverts(
      superAppInstance.updateItemPrice("Shirt", 2, { from: accounts[0] }),
      "Item does not exist"
    );
  });

  it("Update Item Price (Same as previous price)", async () => {
    truffleAssert.reverts(
      superAppInstance.updateItemPrice("Chair", 2, { from: accounts[0] }),
      "Item price did not change"
    );
  });

  it("Update Item Price", async () => {
    let v1 = await superAppInstance.updateItemPrice("Chair", 1, {
      from: accounts[0],
    });
    truffleAssert.eventEmitted(
      v1,
      "itemPriceUpdated",
      (args) => {
        return args.item == "Chair" && args.oldPrice == 2 && args.newPrice == 1;
      },
      "The item price was not updated correctly"
    );
  });

  it("Delete Item (Don't exist)", async () => {
    truffleAssert.reverts(
      superAppInstance.deleteItem("Shirt", { from: accounts[0] }),
      "Item does not exist"
    );
  });

  it("Delete Item", async () => {
    let v1 = await superAppInstance.deleteItem("Chicken");
    truffleAssert.eventEmitted(
      v1,
      "itemRemoved",
      (args) => {
        return args.removedItem == "Chicken";
      },
      "The item was not deleted correctly"
    );
  });

  it("Get items list", async () => {
    await superAppInstance.addItem("Chicken", 1);
    await superAppInstance.addItem("Cloth", 3);
    let v1 = await superAppInstance.getItemsList();
    assert.equal(v1[0], "Chair", "Item lists generated do not match.");
    assert.equal(v1[1], "Chicken", "Item lists generated do not match.");
    assert.equal(v1[2], "Cloth", "Item lists generated do not match.");
  });

  it("Get items price (Don't exist)", async () => {
    let v1 = await superAppInstance.getItemPrice("Chicken");
    assert.equal(v1, 1, "Item price generated does not match.");
  });

  it("Get items price (Don't exist)", async () => {
    truffleAssert.reverts(
      superAppInstance.getItemPrice("Coke"),
      "Item does not exist"
    );
  });

  it("Transfer Ownership and Get Owner", async () => {
    await superAppInstance.transfer(accounts[2], { from: accounts[0] });
    let v1 = await superAppInstance.getOwner();
    let v2 = await superAppInstance.getPrevOwner();

    assert.equal(v1, accounts[2], "Failed to get owner address");
    assert.equal(v2, accounts[0], "Failed to get previous owner address");
  });
});
