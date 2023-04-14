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
        opened
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
    event itemBidded(string itemName, uint256 remainingQuota);
    event itemsBidded(
        string itemName,
        uint256 numberDonated,
        uint256 remainingQuota
    );
    event CTTransferToOwner(uint256 CTAmt);

    mapping(string => uint256) minDonateAmount; // unit cost of donating per item as set by marketplace POC [To factor in resuce team maintenance fee]
    mapping(string => uint256) itemQuota; // quota to hit for each item as set by marketplace POC
    mapping(string => uint256) currentFulfillment; // records the current number of donors for required items

    mapping(string => bool) allItemsIsExist; // records the items that exists for referencing
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

    modifier notBidding() {
        require(
            status == MarketplaceState.closed,
            "Function cannot be called once the marketplace is opened for bidding"
        );
        _;
    }

    modifier duringBidding() {
        require(
            status == MarketplaceState.opened,
            "Function cannot be called as the marketplace is not opened for bidding"
        );
        _;
    }

    modifier biddersOnly() {
        require(
            msg.sender != owner,
            "Only the bidders can get, check and return Charity Tokens, or bid"
        );
        _;
    }

    // functions
    // For marketplace to view what items are available and their prices
    function getAllAvailableItemsAndPrices()
        public
        ownerOnly
        notBidding
        returns (string[] memory, uint256[] memory)
    {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        string[] memory allItemsList = superAppContract.getItemsList();

        for (uint i = 0; i < allItemsList.length; i++) {
            allItemsIsExist[allItemsList[i]] = true;
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
    ) public ownerOnly notBidding {
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
            require(
                allItemsIsExist[itemName] == true,
                string(
                    abi.encodePacked(
                        "THe following item does not exist: ",
                        requiredItemsList[i]
                    )
                )
            );
            itemQuota[itemName] = requiredItemsQuota[i];
            minDonateAmount[itemName] = superAppContract.getItemPrice(
                requiredItemsList[i]
            );
        }

        emit itemsRequiredSet(requiredItemsList);
    }

    // Assumption for overloaded function: Marketplace will set either the min price as provided by the store, or set a higher price to earn fees, along with the quota, in the correct sequence
    function setRequiredItemsInfoManual(
        string[] memory requiredItems,
        uint256[] memory requiredItemsQuota,
        uint256[] memory requiredItemsPrices
    ) public ownerOnly notBidding {
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
            require(
                allItemsIsExist[itemName] == true,
                string(
                    abi.encodePacked(
                        "THe following item does not exist: ",
                        requiredItemsList[i]
                    )
                )
            );
            itemQuota[itemName] = requiredItemsQuota[i];
            require(requiredItemsPrices[i] >= superAppContract.getItemPrice(itemName),
            "Min donation amount cannot be less than the item's original price");
            minDonateAmount[itemName] = requiredItemsPrices[i];
        }

        emit itemsRequiredSet(requiredItemsList);
    }

    // for marketplace to update specific items
    function updateItemQuota(
        string memory _itemName,
        uint256 _newQuota
    ) public ownerOnly notBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        require(
            itemQuota[_itemName] != 0,
            "THe item has not been added into the required item list."
        );

        require(
            itemQuota[_itemName] != _newQuota,
            "The old and new quota should not be the same"
        );

        itemQuota[_itemName] = _newQuota;
        emit itemQuotaUpdated(_itemName, _newQuota);
    }

    function updateItemMinDonation(
        string memory _itemName,
        uint256 _newMinDonation
    ) public ownerOnly notBidding {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        require(
            minDonateAmount[_itemName] != 0,
            "THe item has not been added into the required item list."
        );

        require(
            minDonateAmount[_itemName] != _newMinDonation,
            "The old and new min donation should not be the same"
        );

        require(
            _newMinDonation >= superAppContract.getItemPrice(_itemName),
            "The new min donation cannot be less than the item's original price"
        );

        itemQuota[_itemName] = _newMinDonation;
        emit itemMinDonationUpdated(_itemName, _newMinDonation);
    }

    // Open the market and allow bidders to start bidding
    function start_bidding() public ownerOnly notBidding {
        status = MarketplaceState.opened;
    }

    function stop_bidding() public ownerOnly duringBidding {
        status = MarketplaceState.closed;
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

    function getCurrentFulfillment(
        string memory _itemName
    ) public view returns (uint256) {
        return currentFulfillment[_itemName];
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

    function bidForItem(
        string memory _itemName
    ) public biddersOnly duringBidding {
        uint256 quotaRemaining = getNumDonorsToQuota(_itemName);
        require(quotaRemaining > 0, "No more quota remaining");
        uint256 minDonationAmt = getItemPerUnitDonationAmount(_itemName);
        require(
            charityTokenContract.checkCredit(msg.sender) >= minDonationAmt,
            "Not enough CT"
        );
        charityTokenContract.transferCredit(address(this), minDonationAmt);
        currentFulfillment[_itemName] = currentFulfillment[_itemName] + 1;
        emit itemBidded(_itemName, getNumDonorsToQuota(_itemName));
    }

    function bidForItemWithQuantity(
        string memory _itemName,
        uint256 _quantityToDonate
    ) public biddersOnly duringBidding {
        uint256 quotaRemaining = getNumDonorsToQuota(_itemName);
        require(quotaRemaining > 0, "No more quota remaining");
        require(
            quotaRemaining > _quantityToDonate,
            "The quota remaining required is less than the amount you would like to donate."
        );
        uint256 minDonationAmt = getItemPerUnitDonationAmount(_itemName);
        require(
            charityTokenContract.checkCredit(msg.sender) >=
                (minDonationAmt * _quantityToDonate),
            "Not enough CT"
        );
        charityTokenContract.transferCredit(address(this), minDonationAmt * _quantityToDonate);
        currentFulfillment[_itemName] =
            currentFulfillment[_itemName] +
            _quantityToDonate;
        emit itemsBidded(
            _itemName,
            _quantityToDonate,
            getNumDonorsToQuota(_itemName)
        );
    }

    function getItemsAndRemainingQuota()
        public
        view
        ownerOnly
        returns (string[] memory, uint256[] memory)
    {
        uint256[] memory quotaList = new uint256[](requiredItemsList.length);
        for (uint i = 0; i < requiredItemsList.length; i++) {
            string memory itemName = requiredItemsList[i];
            uint256 quotaRemaining = itemQuota[itemName] -
                currentFulfillment[itemName];
            quotaList[i] = quotaRemaining;
        }

        return (requiredItemsList, quotaList);
    }

    function stopBiddingAndTransferCTToOwner() public ownerOnly duringBidding {
        uint256 contractCTAmt = charityTokenContract.checkCredit(address(this));
        charityTokenContract.transferCreditFrom(
            address(this),
            owner,
            contractCTAmt
        );
        status = MarketplaceState.closed;
        emit CTTransferToOwner(contractCTAmt);
    }
}
