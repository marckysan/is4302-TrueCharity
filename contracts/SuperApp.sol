pragma solidity ^0.5.0;

import "./CharityToken.sol";
import "./StringAsKey.sol";

contract SuperApp {
    struct item {
        string itemName;
        uint256 minPriceInCT;
        string itemCategory;
        address owner;
        address prevOwner;
        bool isValid;
    }

    struct category {
        mapping(bytes32 => item) items;
        string[] itemNames;
        uint256 categoryMinBidinCT;
        string categoryName;
        address owner;
        address prevOwner;
        bool isValid;
    }

    item public firstItem;
    category public firstCategory;
    mapping(bytes32 => category) public categoryMapping;

    // event itemAdded(string cat, item newItem);
    // event itemRemoved(string cat, item existingItem);

    CharityToken charityTokenContract;
    StringAsKey stringAsKeyContract;

    // Initialise the superapp with the requirement that it must have at least 1 category with 1 item
    constructor(
        CharityToken charityTokenAddress,
        StringAsKey stringAsKeyAddress,
        string memory _firstCategory,
        string memory _firstItem,
        uint256 _itemMinPrice
    ) public {
        charityTokenContract = charityTokenAddress;
        stringAsKeyContract = stringAsKeyAddress;
        bytes32 firstCategoryKey = stringAsKeyContract.convert(_firstCategory);
        bytes32 firstItemKey = stringAsKeyContract.convert(_firstItem);

        firstItem = item(
            _firstItem,
            _itemMinPrice,
            _firstCategory,
            address(this),
            address(0),
            true
        );

        string[] memory itemArr = new string[](1);
        itemArr[0] = _firstItem;
        firstCategory = category(
            itemArr,
            _itemMinPrice,
            _firstCategory,
            address(this),
            address(0),
            true
        );
        firstCategory.items[firstItemKey] = firstItem;
        categoryMapping[firstCategoryKey] = firstCategory;
    }

    function addCategory(string memory _categoryName) public {
        bytes32 categoryKey = stringAsKeyContract.convert(_categoryName);

        require(
            !categoryMapping[categoryKey].isValid,
            "Category already exists, please update the category instead."
        );

        string[] memory itemArr = new string[](1);
        category memory newCategory = category(
            itemArr,
            0,
            _categoryName,
            address(this),
            address(0),
            true
        );
        categoryMapping[categoryKey] = newCategory;
    }

    function deleteCategory(string memory _categoryName) public {
        bytes32 categoryKey = stringAsKeyContract.convert(_categoryName);
        require(
            categoryMapping[categoryKey].isValid,
            "The requested category does not exist, it cannot be deleted."
        );

        delete categoryMapping[categoryKey];
    }

    function addItem(
        string memory _itemName,
        uint256 _itemMinPriceInCT,
        string memory _categoryName
    ) public {
        bytes32 categoryKey = stringAsKeyContract.convert(_categoryName);
        bytes32 itemKey = stringAsKeyContract.convert(_itemName);
        require(_itemMinPriceInCT > 0, "Item cannot be free");
        require(
            categoryMapping[categoryKey].isValid,
            "The requested category does not exist, please create it first."
        );
        require(
            !categoryMapping[categoryKey].items[itemKey].isValid,
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

        categoryMapping[categoryKey].items[itemKey] = newItem;
        categoryMapping[categoryKey].itemNames.push(_itemName);

        // Update category min bid if the item price is higher than curr min bid
        uint256 currMinBid = categoryMapping[categoryKey].categoryMinBidinCT;
        if (currMinBid < _itemMinPriceInCT) {
            categoryMapping[categoryKey].categoryMinBidinCT = _itemMinPriceInCT;
        }
    }

    function deleteItem(
        string memory _itemName,
        string memory _categoryName
    ) public {
        bytes32 categoryKey = stringAsKeyContract.convert(_categoryName);
        bytes32 itemKey = stringAsKeyContract.convert(_itemName);
        require(
            categoryMapping[categoryKey].items[itemKey].isValid,
            "Item does not exists in the category, please delete a valid item instead."
        );

        // Delete the item
        uint256 itemMinPrice = categoryMapping[categoryKey]
            .items[itemKey]
            .minPriceInCT;
        delete categoryMapping[categoryKey].items[itemKey];

        // Update the category min bid
        if (categoryMapping[categoryKey].categoryMinBidinCT == itemMinPrice) {
            uint256 minPrice = 10000000000000000;
            uint256 length = categoryMapping[categoryKey].itemNames.length;
            for (uint256 i = 0; i < length; i++) {
                bytes32 indexName = stringAsKeyContract.convert(
                    categoryMapping[categoryKey].itemNames[i]
                );
                if (indexName == itemKey) {
                    string[] storage itemsArr = categoryMapping[categoryKey]
                        .itemNames;
                    itemsArr[i] = itemsArr[itemsArr.length - 1];
                    itemsArr.pop();
                    categoryMapping[categoryKey].itemNames = itemsArr;
                } else {
                    uint256 itemIteratedPrice = categoryMapping[categoryKey]
                        .items[itemKey]
                        .minPriceInCT;
                    if (itemIteratedPrice < minPrice) {
                        minPrice = itemIteratedPrice;
                    }
                }
            }
            categoryMapping[categoryKey].categoryMinBidinCT = minPrice;
        }
    }

    // //transfer ownership to new owner
    // function transfer(
    //     uint256 diceId,
    //     address newOwner
    // ) public ownerOnly(diceId) validDiceId(diceId) {
    //     dices[diceId].prevOwner = dices[diceId].owner;
    //     dices[diceId].owner = newOwner;
    // }
}
