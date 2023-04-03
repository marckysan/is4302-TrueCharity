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

  it("Add Category (Not Owner)", async () => {
    truffleAssert.reverts(
      superAppInstance.addCategory("Meat", { from: accounts[1] }),
      "Only the owner of the superapp contract can call this function"
    );
  });

  it("Add Category", async () => {
    let v1 = await superAppInstance.addCategory.call("Meat", {
      from: accounts[0],
    });
    assert.equal(v1, true, "Failed to add category");
  });

  it("Add Category (Duplicate category)", async () => {
    await superAppInstance.addCategory("Meat");
    await truffleAssert.reverts(
      superAppInstance.addCategory("Meat"),
      "Category already exists, please update the category instead"
    );
  });

  it("Update Category Name (Don't exist)", async () => {
    await truffleAssert.reverts(
      superAppInstance.updateCategoryName("Drinks", "Wheat"),
      "The requested category does not exist, it cannot be updated"
    );
  });

  it("Update Category Name (New name already used)", async () => {
    await superAppInstance.addCategory("Carbs");
    await truffleAssert.reverts(
      superAppInstance.updateCategoryName("Meat", "Carbs"),
      "The new name is already used"
    );
  });

  it("Delete Category (Don't exist)", async () => {
    await truffleAssert.reverts(
      superAppInstance.deleteCategory("Drinks"),
      "The requested category does not exist, it cannot be deleted"
    );
  });

  it("Delete Category", async () => {
    let v1 = await superAppInstance.deleteCategory.call("Meat");
    assert.equal(v1, true, "Failed to delete category");
  });

  it("Add Item (0 CT)", async () => {
    await truffleAssert.reverts(
      superAppInstance.addItem("Chicken", 0, "Meat"),
      "Item's min price needs to be more than 0 Charity Token"
    );
  });

  it("Add Item (Category don't exist)", async () => {
    await truffleAssert.reverts(
      superAppInstance.addItem("Milo", 1, "Drinks"),
      "The requested category does not exist, please create it first"
    );
  });

  it("Add Item", async () => {
    let v1 = await superAppInstance.addItem.call("Chicken", 1, "Meat");
    assert.equal(v1, true, "Failed to add item");
  });

  it("Add Item (Duplicate item)", async () => {
    await superAppInstance.addItem("Chicken", 2, "Meat");
    await truffleAssert.reverts(
      superAppInstance.addItem("Chicken", 2, "Meat"),
      "Item already exists in the category, please update the item instead"
    );
  });

  it("Update Item (Min price)", async () => {
    let v1 = await superAppInstance.updateItem.call("Chicken", 1);
    assert.equal(v1, true, "Failed to update item's minmum price");
  });

  it("Update Item (Min price = 0)", async () => {
    await truffleAssert.reverts(
      superAppInstance.updateItem("Chicken", 0),
      "New price must be more than 0 Charity Token"
    );
  });

  it("Update Item (Item don't exist)", async () => {
    await truffleAssert.reverts(
      superAppInstance.updateItem("Beef", 1),
      "Item does not exist"
    );
  });

  it("Update Item (Min price, validity)", async () => {
    let v1 = await superAppInstance.updateItem.call("Chicken", 1, false);
    assert.equal(v1, true, "Failed to update item's minmum price and validity");
  });

  it("Update Item (Min price, validity, name)", async () => {
    let v1 = await superAppInstance.updateItem.call(
      "Chicken",
      1,
      false,
      "Beef"
    );
    assert.equal(
      v1,
      true,
      "Failed to update item's minmum price, validity, and name"
    );
  });

  it("Update Item (Name already exists)", async () => {
    await truffleAssert.reverts(
      superAppInstance.updateItem("Chicken", 1, false, "Chicken"),
      "Item's name already exists, use another name"
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
