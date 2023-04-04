pragma solidity ^0.5.0;

// Based on solidity 0.5.0, this is an experimental feature. Based on later compiler versions, this is stable
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol"; // Uncomment this line for logging
import "./SuperApp.sol";
import "./CharityToken.sol";

contract Marketplace {
    address owner;
    CharityToken charityTokenContract;
    SuperApp superAppContract;

    enum MarketplaceState {
        closed,
        open,
        voting
    }
    MarketplaceState status;

    // Initialise the marketplace with the requirement that it must have at least 1 category with 1 item
    constructor(
        CharityToken charityTokenAddress,
        SuperApp superAppAddress
    ) public {
        charityTokenContract = charityTokenAddress;
        superAppContract = superAppAddress;
        owner = msg.sender; // setting owner to be the marketplace POC
        status = MarketplaceState.closed;
    }

    // Bidder's events
    event buyCredit(uint256 ctAmount); // event of minting of CT to the msg.sender
    event returnCredits(uint256 ctAmount); // event of returning of CT of the msg.sender

    // Marketplace events
    event biddingInitiated(MarketplaceState state); // event of initiating bidding
    event allItemsRetrieved(string[] itemsList); // event of retrieving the list of items
    event allItemsPricesRetrieved(uint256[] prices); // event of retrieving the prices of all items
    event itemsRequiredSet(string[] requiredItemsList); // event of having set the items required by the rescue team
    event itemQuotaUpdated(string itemName, uint256 quota); // event of having updated the item quota
    event itemMinDonationUpdated(string itemName, uint256 minDonation); // event of having updated the item min donation

    mapping(string => uint256) minDonateAmount; // unit cost of donating per item as set by marketplace POC [To factor in resuce team maintenance fee]
    mapping(string => uint256) itemQuota; // quota to hit for each item as set by marketplace POC
    mapping(string => uint256) currentFulfillment; // records the current number of donors for required items
    string[] public requiredItemsList;
    uint256[] public allItemsPriceList;

    // modifiers
    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of the marketplace contract can call this function"
        );
        _;
    }

    modifier beforeBidding() {
        require(
            status == MarketplaceState.closed,
            "Function cannot be called once the marketplace is opened for donating"
        );
        _;
    }

    modifier biddersOnly() {
        require(
            msg.sender != owner,
            "Only the bidders can get, check and return Charity Tokens"
        );
        _;
    }

    // functions
    // For marketplace to view what items are available and their prices
    function getAllAvailableItemsAndPrices()
        public
        ownerOnly
        beforeBidding
        returns (string[] memory allItemsList, uint256[] memory)
    {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        allItemsList = superAppContract.getItemsList();
        for (uint i = 0; i < allItemsList.length; i++) {
            allItemsPriceList.push(
                superAppContract.getItemPrice(allItemsList[i])
            );
        }

        emit allItemsRetrieved(allItemsList);
        emit allItemsPricesRetrieved(allItemsPriceList);

        return (allItemsList, allItemsPriceList);
    }

    function setRequiredItemsInfo(
        string[] memory requiredItems,
        uint256[] memory requiredItemsQuota
    ) public ownerOnly beforeBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );
        require(
            requiredItems.length == requiredItemsQuota.length,
            "The number of required items in the required items list and required items quota do not match."
        );
        requiredItemsList = requiredItems;
        for (uint256 i = 0; i < requiredItemsList.length; i++) {
            string memory itemName = requiredItemsList[i];
            itemQuota[itemName] = requiredItemsQuota[i];
            minDonateAmount[itemName] = superAppContract.getItemPrice(
                requiredItemsList[i]
            );
        }

        emit itemsRequiredSet(requiredItemsList);
    }

    // Assumption for overloaded function: Marketplace will set either the min price as provided by the store, or set a higher price to earn fees, along with the quota, in the correct sequence
    function setRequiredItemsInfo(
        string[] memory requiredItems,
        uint256[] memory requiredItemsQuota,
        uint256[] memory requiredItemsPrices
    ) public ownerOnly beforeBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );
        require(
            requiredItems.length == requiredItemsQuota.length &&
                requiredItems.length == requiredItemsPrices.length,
            "The number of required items in the required items list and required items quota and required items prices do not match."
        );
        requiredItemsList = requiredItems;
        for (uint256 i = 0; i < requiredItemsList.length; i++) {
            string memory itemName = requiredItemsList[i];
            itemQuota[itemName] = requiredItemsQuota[i];
            minDonateAmount[itemName] = requiredItemsPrices[i];
        }

        emit itemsRequiredSet(requiredItemsList);
    }

    // for marketplace to update specific items
    function updateItemQuota(
        string memory _itemName,
        uint256 _newQuota
    ) public ownerOnly beforeBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        require(
            itemQuota[_itemName] != 0,
            "THe item has not been added into the required item list."
        );

        itemQuota[_itemName] = _newQuota;
        emit itemQuotaUpdated(_itemName, _newQuota);
    }

    function updateItemMinDonation(
        string memory _itemName,
        uint256 _newMinDonation
    ) public ownerOnly beforeBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        require(
            minDonateAmount[_itemName] != 0,
            "THe item has not been added into the required item list."
        );

        itemQuota[_itemName] = _newMinDonation;
        emit itemMinDonationUpdated(_itemName, _newMinDonation);
    }

    // Open the market and allow bidders to start bidding
    function start_bidding() public ownerOnly beforeBidding {
        status = MarketplaceState.open;
    }

    function getStatus() public view returns (MarketplaceState) {
        return status;
    }

    // Functions for bidders

    // Getting all donatable items
    function getDonatableItemOptions() public view returns (string[] memory) {
        return requiredItemsList;
    }

    // Getting the amount to be donated per unit for a specific item,
    function getItemPerUnitDonationAmount(
        string memory _itemName
    ) public view returns (uint256) {
        require(minDonateAmount[_itemName] != 0, "Item does not exist.");
        return minDonateAmount[_itemName];
    }

    function getNumDonorsToQuota(
        string memory _itemName
    ) public view returns (uint256) {
        require(
            itemQuota[_itemName] != 0,
            "Item is not needed in this charity drive or item does not exist."
        );
        return itemQuota[_itemName] - currentFulfillment[_itemName];
    }

    function getCT() public payable biddersOnly {
        require(msg.value >= 1E16, "At least 0.01ETH needed to get DT");
        charityTokenContract.getCredit(msg.sender, msg.value);
        emit buyCredit(msg.value / 1E16);
    }

    function checkCT() public view biddersOnly returns (uint256) {
        uint256 remainValue = charityTokenContract.checkCredit(msg.sender);
        return remainValue;
    }

    function returnCT(uint256 CTToReturn) public biddersOnly {
        uint256 balance = checkCT();
        require(
            balance > CTToReturn,
            "You do not have sufficient Charity Tokens to return"
        );
        charityTokenContract.transferCredit(address(this), CTToReturn);
        address payable recipient = address(msg.sender);
        uint256 toRetInWei = CTToReturn * 10000000000000000;
        recipient.transfer(toRetInWei);
        emit returnCredits(CTToReturn);
    }
}
