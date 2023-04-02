pragma solidity ^0.5.0;

// Based on solidity 0.5.0, this is an experimental feature. Based on later compiler versions, this is stable
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol"; // Uncomment this line for logging
import "./CharityToken.sol";

contract SuperApp {
    address owner;
    CharityToken charityTokenContract;
    mapping(string => category) private categoryMapping;
    mapping(string => item) private itemMapping;
    store private s;

    struct item {
        string itemName;
        uint256 priceinCT;
        string itemCategory;
        bool isValid;
    }

    struct category {
        mapping(string => item) items;
        string[] itemNames;
        uint256 minItemPriceinCT;
        string categoryName;
        bool isValid;
    }

    struct store {
        mapping(string => category) categories;
        string[] categoryNames;
        address owner;
        address prevOwner;
    }

    // event itemAdded(string cat, item newItem);
    // event itemRemoved(string cat, item existingItem);

    // Initialise the superapp with the requirement that it must have at least 1 category with 1 item
    constructor(CharityToken charityTokenAddress) public {
        charityTokenContract = charityTokenAddress;
        owner = msg.sender; // setting owner to be the superapp POC

        // Initialise the store
        string[] memory catNamesArr;
        s.categoryNames = catNamesArr;
        s.prevOwner = address(0);
        s.owner = owner;
    }

    // modifiers
    // modifier to ensure only owner of contract can invoke function
    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function"
        );
        _;
    }

    // functions

    // For updating store categories mapping
    function updateStoreCategory(
        string memory _categoryName,
        category memory updatedCategory
    ) private {
        s.categories[_categoryName] = updatedCategory;
    }

    // For updating store category list mapping
    function updateStoreCategoryList(string memory _categoryName) private {
        s.categoryNames.push(_categoryName);
    }

    function deleteStoreCategory(string memory _categoryName) private {
        delete s.categories[_categoryName];
        for (uint256 i = 0; i < s.categoryNames.length; i++) {
            string memory categoryName = s.categoryNames[i];
            if (
                keccak256(abi.encodePacked(categoryName)) ==
                keccak256(abi.encodePacked(_categoryName))
            ) {
                s.categoryNames[i] = s.categoryNames[
                    s.categoryNames.length - 1
                ];
                s.categoryNames.pop();
                break;
            }
        }
    }

    function addCategory(
        string memory _categoryName
    ) public ownerOnly returns (bool) {
        require(
            !categoryMapping[_categoryName].isValid,
            "Category already exists, please update the category instead"
        );

        category memory c;
        c.minItemPriceinCT = 0;
        c.categoryName = _categoryName;
        c.isValid = true;

        categoryMapping[_categoryName] = c;
        updateStoreCategory(_categoryName, c);
        updateStoreCategoryList(_categoryName);

        return true;
    }

    function updateCategoryName(
        string memory _categoryName,
        string memory newName
    ) public ownerOnly {
        require(
            categoryMapping[_categoryName].isValid,
            "The requested category does not exist, it cannot be updated"
        );
        require(
            !categoryMapping[newName].isValid,
            "The new name is already used"
        );

        categoryMapping[_categoryName].categoryName = newName;
        category memory c = categoryMapping[_categoryName];

        updateStoreCategory(_categoryName, c);
    }

    function deleteCategory(
        string memory _categoryName
    ) public ownerOnly returns (bool) {
        require(
            categoryMapping[_categoryName].isValid,
            "The requested category does not exist, it cannot be deleted"
        );

        delete categoryMapping[_categoryName];
        deleteStoreCategory(_categoryName);

        return true;
    }

    function addItem(
        string memory _itemName,
        uint256 _priceInCT,
        string memory _categoryName
    ) public ownerOnly returns (bool) {
        require(
            _priceInCT > 0,
            "Item's min price needs to be more than 0 Charity Token"
        );
        require(
            categoryMapping[_categoryName].isValid,
            "The requested category does not exist, please create it first"
        );
        require(
            !categoryMapping[_categoryName].items[_itemName].isValid,
            "Item already exists in the category, please update the item instead"
        );

        // Create and add new item into the category
        item memory newItem = item(_itemName, _priceInCT, _categoryName, true);

        category storage c = categoryMapping[_categoryName];

        // update minimum item price of category
        if (c.itemNames.length <= 0) {
            // if category does not have any items yet
            c.minItemPriceinCT = _priceInCT;
        } else {
            if (_priceInCT < c.minItemPriceinCT) {
                c.minItemPriceinCT = _priceInCT;
            }
        }

        c.items[_itemName] = newItem;
        c.itemNames.push(_itemName);
        itemMapping[_itemName] = newItem;

        updateStoreCategory(_categoryName, c);

        return true;
    }

    function updateCategoryItem(
        string memory _categoryName,
        item memory updatedItem
    ) private {
        category storage c = categoryMapping[_categoryName];
        c.items[updatedItem.itemName] = updatedItem;
        if (updatedItem.priceinCT < c.minItemPriceinCT) {
            c.minItemPriceinCT = updatedItem.priceinCT;
        }

        updateStoreCategory(_categoryName, c);
    }

    // function overloading for updateItem to allow "optional" parameters
    function updateItem(
        string memory _itemName,
        uint256 _newPriceinCT
    ) public ownerOnly returns (bool) {
        require(
            _newPriceinCT > 0,
            "New price must be more than 0 Charity Token"
        );
        require(itemMapping[_itemName].isValid, "Item does not exist");

        string memory categoryOfItem = itemMapping[_itemName].itemCategory;
        item memory updatedItem = itemMapping[_itemName];
        updatedItem.priceinCT = _newPriceinCT;
        itemMapping[_itemName] = updatedItem;
        updateCategoryItem(categoryOfItem, updatedItem);

        return true;
    }

    function updateItem(
        string memory _itemName,
        uint256 _newPriceinCT,
        bool isValid
    ) public ownerOnly returns (bool) {
        require(
            _newPriceinCT > 0,
            "New price must be more than 0 Charity Token"
        );
        require(itemMapping[_itemName].isValid, "Item does not exist");

        string memory categoryOfItem = itemMapping[_itemName].itemCategory;
        item memory updatedItem = itemMapping[_itemName];
        updatedItem.priceinCT = _newPriceinCT;
        updatedItem.isValid = isValid;
        itemMapping[_itemName] = updatedItem;
        updateCategoryItem(categoryOfItem, updatedItem);

        return true;
    }

    // // TODO: Update item method (name, category, min price, validity --> Can invalidate it for archival purposes etc)
    function updateItem(
        string memory _itemName,
        uint256 _newPriceinCT,
        bool isValid,
        string memory _newName
    ) public ownerOnly returns (bool) {
        require(
            _newPriceinCT > 0,
            "New price must be more than 0 Charity Token"
        );
        require(itemMapping[_itemName].isValid, "Item does not exist");
        require(
            !itemMapping[_newName].isValid,
            "Item's name already exists, use another name"
        );

        string memory categoryOfItem = itemMapping[_itemName].itemCategory;
        item memory updatedItem = itemMapping[_itemName];
        updatedItem.priceinCT = _newPriceinCT;
        updatedItem.isValid = isValid;
        updatedItem.itemName = _newName;
        itemMapping[_itemName] = updatedItem;
        updateCategoryItem(categoryOfItem, updatedItem);

        return true;
    }

    function deleteItem(
        string memory _itemName,
        string memory _categoryName
    ) public ownerOnly {
        require(
            categoryMapping[_categoryName].items[_itemName].isValid,
            "Item does not exists in the category, please delete a valid item instead."
        );

        // Delete the item
        uint256 itemMinPrice = categoryMapping[_categoryName]
            .items[_itemName]
            .priceinCT;
        delete categoryMapping[_categoryName].items[_itemName];

        // Update the category min bid
        if (categoryMapping[_categoryName].minItemPriceinCT == itemMinPrice) {
            uint256 minPrice = 10000000000000000;
            uint256 length = categoryMapping[_categoryName].itemNames.length;
            for (uint256 i = 0; i < length; i++) {
                string memory indexName = categoryMapping[_categoryName]
                    .itemNames[i];
                /* solidity does not take string as a primitive type, 
                so we have to hash both strings and compare the result as follows */
                if (
                    keccak256(abi.encodePacked(indexName)) ==
                    keccak256(abi.encodePacked(_itemName))
                ) {
                    string[] storage itemsArr = categoryMapping[_categoryName]
                        .itemNames;
                    itemsArr[i] = itemsArr[itemsArr.length - 1];
                    itemsArr.pop();
                    categoryMapping[_categoryName].itemNames = itemsArr;
                } else {
                    uint256 itemIteratedPrice = categoryMapping[_categoryName]
                        .items[_itemName]
                        .priceinCT;
                    if (itemIteratedPrice < minPrice) {
                        minPrice = itemIteratedPrice;
                    }
                }
            }
            categoryMapping[_categoryName].minItemPriceinCT = minPrice;
        }
        updateStoreCategory(_categoryName, categoryMapping[_categoryName]);
    }

    // Transfer mapping ownership to marketplace through implementation of store strucutre
    function transfer(address newOwner) public ownerOnly {
        s.prevOwner = owner;
        s.owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return s.owner;
    }

    function getPrevOwner() public view returns (address) {
        return s.prevOwner;
    }

    function getCategoryNames() public view returns (string[] memory) {
        return s.categoryNames;
    }

    function getCategoryMinPrice(
        string memory _categoryName
    ) public view ownerOnly returns (uint256) {
        return categoryMapping[_categoryName].minItemPriceinCT;
    }
}
