pragma solidity ^0.5.0;

import "./ERC20.sol";

contract CharityToken {
    ERC20 erc20Contract;
    uint256 supplyLimit;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
        supplyLimit = 1000000000; // billion
    }

    /**
     * @dev Function to give CT to the recipient for a given wei amount
     * @param recipient address of the recipient that wants to buy the CT
     * @param weiAmt uint256 amount indicating the amount of wei that was passed
     * @return A uint256 representing the amount of CT bought by the msg.sender.
     */
    function getCredit(
        address recipient,
        uint256 weiAmt
    ) public returns (uint256) {
        uint256 amt = weiAmt / 10000000000000000; // Convert weiAmt to Charity Token
        require(erc20Contract.totalSupply() + amt <= supplyLimit, "CT supply is not enough");
        erc20Contract.mint(recipient, amt);
        return amt;
    }

    /**
     * @dev Function to check the amount of CT the msg.sender has
     * @param ad address of the recipient that wants to check their CT
     * @return A uint256 representing the amount of CT owned by the msg.sender.
     */
    function checkCredit(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    /**
     * @dev Function to transfer the credit from the owner to the recipient
     * @param recipient address of the recipient that will gain CT
     * @param amt uint256 amount of CT to transfer
     */
    function transferCredit(address recipient, uint256 amt) public {
        erc20Contract.transfer(recipient, amt);
    }

    /**
     * @dev Function to transfer the credit from sender to recipient
     * @param sender address of the sender that sends the CT
     * @param recipient address of the recipient that will gain CT
     * @param amt uint256 amount of CT to transfer
     */
     function transferCreditFrom(address sender, address recipient, uint256 amt) public {
        erc20Contract.transferFrom(sender, recipient, amt);
     }
}
