pragma solidity ^0.5.0;

import "./CharityToken.sol";
import "./StringAsKey.sol";

contract SuperApp {
    address owner;
    CharityToken charityTokenContract;
    mapping(string => category) private categoryMapping;

    struct item {
        string itemName;
        uint256 minPriceInCT;
        string itemCategory;
        address owner;
        address prevOwner;
        bool isValid;
    }

    struct category {
        mapping(string => item) items;
        string[] itemNames;
        uint256 categoryMinBidinCT;
        string categoryName;
        address owner;
        address prevOwner;
        bool isValid;
    }

    // TODO: Implement store structure so that ownership of mapping can be transferred
    // struct store {
    //     categoryMapping;
    //     string name;
    //     address owner;
    //     address prevOwner;
    // }

    // event itemAdded(string cat, item newItem);
    // event itemRemoved(string cat, item existingItem);

    // Initialise the superapp with the requirement that it must have at least 1 category with 1 item
    constructor(
        CharityToken charityTokenAddress
    ) public {
        charityTokenContract = charityTokenAddress;
        owner = msg.sender; // setting owner to be the superapp POC
    }

    // modifiers
    // modifier to ensure only owner of contract can invoke function
    modifier ownerOnly() {
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        _;
    }

    // functions
    function addCategory(string memory _categoryName) public ownerOnly() {
        require(
            !categoryMapping[_categoryName].isValid,
            "Category already exists, please update the category instead"
        );

        category memory c;
        c.categoryMinBidinCT = 0;
        c.categoryName = _categoryName;
        c.owner = address(this);
        c.prevOwner = address(0);
        c.isValid = true;

        categoryMapping[_categoryName] = c;
    }

    function getCategoryName(string memory _categoryName) view public returns (string memory) {
        require(categoryMapping[_categoryName].isValid, "The requested category does not exist");

        return categoryMapping[_categoryName].categoryName;
    }

    function updateCategoryName(string memory _categoryName, string memory newName) public ownerOnly() {
        require(categoryMapping[_categoryName].isValid, "The requested category does not exist, it cannot be updated");
        require(!categoryMapping[newName].isValid, "The new name is already used");

        categoryMapping[_categoryName].categoryName = newName;
    }

    function deleteCategory(string memory _categoryName) public ownerOnly() {
        require(
            categoryMapping[_categoryName].isValid,
            "The requested category does not exist, it cannot be deleted."
        );

        delete categoryMapping[_categoryName];
    }

    function addItem(
        string memory _itemName,
        uint256 _itemMinPriceInCT,
        string memory _categoryName
    ) public {
        require(_itemMinPriceInCT > 0, "Item cannot be free");
        require(
            categoryMapping[_categoryName].isValid,
            "The requested category does not exist, please create it first."
        );
        require(
            !categoryMapping[_categoryName].items[_itemName].isValid,
            "Item already exists, please update the item instead."
        );

        // Create and add new item into the category
        item memory newItem = item(
            _itemName,
            _itemMinPriceInCT,
            _categoryName,
            address(this),
            address(0),
            true
        );

        categoryMapping[_categoryName].items[_itemName] = newItem;
        categoryMapping[_categoryName].itemNames.push(_itemName);

        // Update category min bid if the item price is higher than curr min bid
        uint256 currMinBid = categoryMapping[_categoryName].categoryMinBidinCT;
        if (currMinBid > _itemMinPriceInCT) {
            categoryMapping[_categoryName].categoryMinBidinCT = _itemMinPriceInCT;
        }
    }

    // TODO: Update item method (name, category, min price, validity --> Can invalidate it for archival purposes etc)
    function updateItem(string memory _itemName, uint256 minPriceInCT, bool isValid) public {
    }

    function deleteItem(
        string memory _itemName,
        string memory _categoryName
    ) public {
        require(
            categoryMapping[_categoryName].items[_itemName].isValid,
            "Item does not exists in the category, please delete a valid item instead."
        );

        // Delete the item
        uint256 itemMinPrice = categoryMapping[_categoryName]
            .items[_itemName]
            .minPriceInCT;
        delete categoryMapping[_categoryName].items[_itemName];

        // Update the category min bid
        if (categoryMapping[_categoryName].categoryMinBidinCT == itemMinPrice) {
            uint256 minPrice = 10000000000000000;
            uint256 length = categoryMapping[_categoryName].itemNames.length;
            for (uint256 i = 0; i < length; i++) {
                string memory indexName = categoryMapping[_categoryName].itemNames[i];
                /* solidity does not take string as a primitive type, 
                so we have to hash both strings and compare the result as follows */
                if (keccak256(abi.encodePacked(indexName)) == keccak256(abi.encodePacked(_itemName))) {
                    string[] storage itemsArr = categoryMapping[_categoryName]
                        .itemNames;
                    itemsArr[i] = itemsArr[itemsArr.length - 1];
                    itemsArr.pop();
                    categoryMapping[_categoryName].itemNames = itemsArr;
                } else {
                    uint256 itemIteratedPrice = categoryMapping[_categoryName]
                        .items[_itemName]
                        .minPriceInCT;
                    if (itemIteratedPrice < minPrice) {
                        minPrice = itemIteratedPrice;
                    }
                }
            }
            categoryMapping[_categoryName].categoryMinBidinCT = minPrice;
        }
    }

    // TODO: Transfer mapping ownership to marketplace through implementation of store strucutre
    function transfer(address newOwner) public {
    }
}
