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

    event buyCredit(uint256 ctAmount); // event of minting of CT to the msg.sender
    event returnCredits(uint256 ctAmount); // event of returning of CT of the msg.sender
    event biddingInitiated(); // event of initiating bidding
    event categoriesRetrieved(string[] categoryList);
    event getOwnerEvent(address owner);

    mapping(string => uint256) private minBidAmount; // Min bid for each category as set out by marketplace POC
    string[] private categoryList;
    mapping(string => bool) private categoriesIsExist;

    // modifiers
    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of the marketplace contract can call this function"
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
    // For marketplace and public to view what categories are available
    function getCategories() public returns (string[] memory) {
        categoryList = superAppContract.getCategoryList();

        emit categoriesRetrieved(categoryList);
        return categoryList;
    }

    // for marketplace to initialise the min bids of all categories based on min price
    function setMinBidToMinPrice() public ownerOnly {
        require(
            superAppContract.getOwner() == owner,
            "SuperApp store ownership has yet to be transferred."
        );

        if (categoryList.length == 0) {
            getCategories();
        }

        for (uint256 i = 0; i < categoryList.length; i++) {
            minBidAmount[categoryList[i]] = superAppContract
                .getCategoryMinPrice(categoryList[i], owner);
            categoriesIsExist[categoryList[i]] = true;
        }
    }

    // for marketplace owner to set min bids for specific categories
    function setCategoryMinBid(
        string memory _categoryName,
        uint256 _minBidInCT
    ) public ownerOnly {
        if (categoryList.length == 0) {
            getCategories();
        }

        minBidAmount[_categoryName] = _minBidInCT;
    }

    // for marketplace and public to get the min bid required for each category
    function getCategoryMinBid(
        string memory _categoryName
    ) public view returns (uint256) {
        require(
            categoriesIsExist[_categoryName] != false,
            "The category minimum bid has yet to be updated. Please wait, or update the minimum bids if you run the marketplace."
        );
        return minBidAmount[_categoryName];
    }

    // Open the market and allow bidders to start bidding
    function start_bidding() public ownerOnly {
        status = MarketplaceState.open;
    }

    function getStatus() public view biddersOnly returns (MarketplaceState) {
        return status;
    }

    // Functions for bidders
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
