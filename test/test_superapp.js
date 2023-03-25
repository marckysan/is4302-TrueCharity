const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
const BigNumber = require("bignumber.js");
const assert = require("assert");

const oneEth = new BigNumber(1000000000000000000);

const CharityToken = artifacts.require("../contracts/CharityToken.sol");
const SuperApp = artifacts.require("../contracts/SuperApp.sol");

contract("SuperApp", function(accounts){
    before(async() => {
        charityTokenInstance = await CharityToken.deployed();
        superAppInstance = await SuperApp.deployed();
    });

    console.log("Testing SuperApp");

    it("Add Category (Not Owner)", async() => {
        truffleAssert.reverts(
            superAppInstance.addCategory("Meat", {from: accounts[1]}),
            "Only the owner of the contract can call this function"
        );
    });

    it("Add Category", async() => {
        await superAppInstance.addCategory("Meat");
        await superAppInstance.addCategory("Carbs");
        let categoryName1 = await superAppInstance.getCategoryName("Meat");
        let categoryName2 = await superAppInstance.getCategoryName("Carbs");
        assert.equal(categoryName1, "Meat", "Failed to add category correctly");
        assert.equal(categoryName2, "Carbs", "Failed to add category correctly");
    })

    it("Add Category (Duplicate)", async() => {
        await truffleAssert.reverts(
            superAppInstance.addCategory("Meat"),
            "Category already exists, please update the category instead"
        );
    });

    it("Update Category Name (Don't exist)", async() => {
        await truffleAssert.reverts(
            superAppInstance.updateCategoryName("Drinks", "Wheat"),
            "The requested category does not exist, it cannot be updated"
        );
    });

    it("Update Category Name (New name already used)", async() => {
        await truffleAssert.reverts(
            superAppInstance.updateCategoryName("Meat", "Carbs"),
            "The new name is already used"
        );
    });

    it("Delete Category (Don't exist)", async() => {
        await truffleAssert.reverts(
            superAppInstance.deleteCategory("Drinks"),
            "The requested category does not exist, it cannot be deleted."
        );
    });

    it("Delete Category", async() => {
        await superAppInstance.deleteCategory("Meat");
        await truffleAssert.reverts(
            superAppInstance.getCategoryName("Meat"),
            "The requested category does not exist"
        );
    });
})