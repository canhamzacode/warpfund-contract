// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WarpFund {
    // ==============================
    // 🔹 State Variables & Structs
    // ==============================
    address public owner;
    uint256 public campaignCount;
    string[] public categories;

    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 fundsRaised;
        bool withdrawn;
        uint256 categoryIndex;
    }

    // ==============================
    // 🔹 Mappings
    // ==============================
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public donations; // campaignId -> donor -> amount
    mapping(uint256 => address[]) public campaignDonors; // campaignId -> list of donors

    // ==============================
    // 🔹 Events
    // ==============================
    event CampaignCreated(
        uint256 campaignId,
        address creator,
        uint256 goal,
        uint256 deadline
    );
    event DonationReceived(uint256 campaignId, address donor, uint256 amount);
    event FundsWithdrawn(uint256 campaignId, address creator, uint256 amount);
    event RefundIssued(uint256 campaignId, address donor, uint256 amount);

    // ==============================
    // 🔹 Modifiers
    // ==============================
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // ==============================
    // 🔹 Constructor
    // ==============================
    constructor(address _owner) {
        require(_owner != address(0), "Invalid owner address");
        owner = _owner;
    }

    // ==============================
    // 🔹 Campaign Management Functions
    // ==============================
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _duration,
        uint256 _categoryIndex
    ) public {
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        uint256 campaignId = campaignCount++;
        campaigns[campaignId] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            deadline: block.timestamp + convertDaysToSeconds(_duration),
            fundsRaised: 0,
            withdrawn: false,
            categoryIndex: _categoryIndex
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            _goal,
            block.timestamp + convertDaysToSeconds(_duration)
        );
    }

    function getCampaign(
        uint256 _campaignId
    ) public view returns (Campaign memory) {
        return campaigns[_campaignId];
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);
        for (uint256 i = 0; i < campaignCount; i++) {
            allCampaigns[i] = campaigns[i];
        }
        return allCampaigns;
    }

    // ==============================
    // 🔹 Donation Functions
    // ==============================
    function donateToCampaign(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be greater than 0");

        if (donations[_campaignId][msg.sender] == 0) {
            campaignDonors[_campaignId].push(msg.sender);
        }

        campaign.fundsRaised += msg.value;
        donations[_campaignId][msg.sender] += msg.value;

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    function getDonors(
        uint256 _campaignId
    ) public view returns (address[] memory) {
        return campaignDonors[_campaignId];
    }

    function getDonorContribution(
        uint256 _campaignId,
        address _donor
    ) public view returns (uint256) {
        return donations[_campaignId][_donor];
    }

    // ==============================
    // 🔹 Fund Withdrawal & Refunds
    // ==============================
    function withdrawFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(
            msg.sender == campaign.creator,
            "Only campaign creator can withdraw"
        );
        require(
            block.timestamp >= campaign.deadline,
            "Campaign is still running"
        );
        require(campaign.fundsRaised >= campaign.goal, "Goal not met");
        require(!campaign.withdrawn, "Funds already withdrawn");

        campaign.withdrawn = true;
        payable(msg.sender).transfer(campaign.fundsRaised);

        emit FundsWithdrawn(_campaignId, msg.sender, campaign.fundsRaised);
    }

    function refund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(
            block.timestamp >= campaign.deadline,
            "Campaign is still running"
        );
        require(campaign.fundsRaised < campaign.goal, "Goal was met");

        uint256 donation = donations[_campaignId][msg.sender];
        require(donation > 0, "No donation found");

        donations[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(donation);

        emit RefundIssued(_campaignId, msg.sender, donation);
    }

    // ==============================
    // 🔹 Category Management
    // ==============================
    function createCategory(string memory _category) public onlyOwner {
        categories.push(_category);
    }

    function setCategories(string[] memory _categories) public onlyOwner {
        for (uint256 i = 0; i < _categories.length; i++) {
            categories.push(_categories[i]);
        }
    }

    function getCampaignCategory(
        uint256 _campaignId
    ) public view returns (string memory) {
        require(_campaignId < categories.length, "Invalid Category Id");
        return categories[campaigns[_campaignId].categoryIndex];
    }

    // ==============================
    // 🔹 Utility Functions
    // ==============================
    function convertDaysToSeconds(uint256 _days) public pure returns (uint256) {
        return _days * 24 * 60 * 60;
    }
}
