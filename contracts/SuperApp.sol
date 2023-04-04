pragma solidity ^0.5.0;

// Based on solidity 0.5.0, this is an experimental feature. Based on later compiler versions, this is stable
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol"; // Uncomment this line for logging
import "./CharityToken.sol";

contract SuperApp {
    address owner;
    address prevOwner;
    CharityToken charityTokenContract;
    mapping(string => item) private itemMapping;
    mapping(string => uint256) private itemIndexMapping;
    string[] itemsList;

    enum UpdateFunction {
        add,
        remove,
        update
    }

    struct item {
        string itemName;
        uint256 priceinCT;
    }

    event itemAdded(string addedItem);
    event itemRemoved(string removedItem);
    event itemNameUpdated(string oldItem, string newItem);
    event itemPriceUpdated(string item, uint256 oldPrice, uint256 newPrice);

    // Initialise the superapp with the requirement that it must have at least 1 category with 1 item
    constructor(CharityToken charityTokenAddress) public {
        charityTokenContract = charityTokenAddress;
        owner = msg.sender; // setting owner to be the superapp POC
    }

    // modifiers
    // modifier to ensure only owner of contract can invoke function
    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of the superapp contract can call this function"
        );
        _;
    }

    // functions
    // Function to update item arr and item index mapping for add and delete
    function updateItemIndexArrMapping(
        string memory _itemName,
        uint256 _index,
        UpdateFunction _function
    ) public ownerOnly {
        if (_function == UpdateFunction.add) {
            itemIndexMapping[_itemName] = _index;
            itemsList.push(_itemName);
        } else if (_function == UpdateFunction.remove) {
            itemsList[_index] = itemsList[itemsList.length - 1];
            itemsList.pop();
            delete itemIndexMapping[_itemName];
            for (uint i = _index; i < itemsList.length; i++) {
                itemIndexMapping[itemsList[i]] = i;
            }
        }
    }

    // Function overloading to update item arr and item index mapping for update
    function updateItemIndexArrMapping(
        string memory _oldItemName,
        string memory _newItemName,
        uint256 _index,
        UpdateFunction _function
    ) public ownerOnly {
        if (_function == UpdateFunction.update) {
            delete itemIndexMapping[_oldItemName];
            itemIndexMapping[_newItemName] = _index;
            itemsList[_index] = _newItemName;
        }
    }

    function addItem(string memory _itemName, uint256 _priceInCT) private {
        require(
            _priceInCT > 0,
            "Item's min price needs to be more than 0 Charity Token"
        );
        require(
            itemMapping[_itemName].priceinCT != 0,
            "Item already exists, please update the item instead"
        );

        // Create and add new item into the category
        item memory newItem = item(_itemName, _priceInCT);
        itemMapping[_itemName] = newItem;
        updateItemIndexArrMapping(
            _itemName,
            itemsList.length + 1,
            UpdateFunction.add
        );
        emit itemAdded(_itemName);
    }

    // function overloading for updateItem to allow "optional" parameters
    function updateItem(
        string memory _itemName,
        string memory _newItemName
    ) private {
        require(itemMapping[_itemName].priceinCT != 0, "Item does not exist");

        item memory updatedItem = itemMapping[_itemName];
        updatedItem.itemName = _newItemName;
        delete itemMapping[_itemName];
        itemMapping[_newItemName] = updatedItem;

        updateItemIndexArrMapping(
            _itemName,
            _newItemName,
            itemIndexMapping[_itemName],
            UpdateFunction.update
        );

        emit itemNameUpdated(_itemName, _newItemName);
    }

    function updateItem(
        string memory _itemName,
        uint256 _newPriceinCT
    ) private {
        require(
            _newPriceinCT > 0,
            "New price must be more than 0 Charity Token"
        );
        require(itemMapping[_itemName].priceinCT != 0, "Item does not exist");

        item memory updatedItem = itemMapping[_itemName];
        uint256 oldPrice = updatedItem.priceinCT;
        updatedItem.priceinCT = _newPriceinCT;
        itemMapping[_itemName] = updatedItem;

        emit itemPriceUpdated(_itemName, oldPrice, _newPriceinCT);
    }

    function deleteItem(string memory _itemName) private {
        require(itemMapping[_itemName].priceinCT != 0, "Item does not exist");

        delete itemMapping[_itemName];
        updateItemIndexArrMapping(
            _itemName,
            itemIndexMapping[_itemName],
            UpdateFunction.remove
        );

        emit itemRemoved(_itemName);
    }

    // Transfer mapping ownership to marketplace through implementation of store strucutre
    function transfer(address newOwner) public ownerOnly {
        prevOwner = owner;
        owner = newOwner;
    }

    function getItemsList() public view returns (string[] memory) {
        return itemsList;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getPrevOwner() public view returns (address) {
        return prevOwner;
    }

    function getItemPrice(
        string memory _itemName
    ) public view returns (uint256) {
        require(itemMapping[_itemName].priceinCT != 0, "Item does not exist");
        return itemMapping[_itemName].priceinCT;
    }
}
