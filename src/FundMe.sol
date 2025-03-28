// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WarpFund {
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

    string[] public categories;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public donations;
    uint256 public campaignCount;

    event CampaignCreated(
        uint256 campaignId,
        address creator,
        uint256 goal,
        uint256 deadline
    );
    event DonationReceived(uint256 campaignId, address donor, uint256 amount);
    event FundsWithdrawn(uint256 campaignId, address creator, uint256 amount);
    event RefundIssued(uint256 campaignId, address donor, uint256 amount);

    function createCategory(string memory _category) public {
        categories.push(_category);
    }

    // add categoris in bulk
    function setCategories(string[] memory _categories) public {
        for (uint256 i = 0; i < _categories.length; i++) {
            categories.push(_categories[i]);
        }
    }

    function getCampaignCategory(
        uint256 _campaignId
    ) public view returns (string memory) {
        return categories[campaigns[_campaignId].categoryIndex];
    }

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
            deadline: block.timestamp + _duration,
            fundsRaised: 0,
            withdrawn: false,
            categoryIndex: _categoryIndex
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            _goal,
            block.timestamp + _duration
        );
    }

    function donateToCampaign(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be greater than 0");

        campaign.fundsRaised += msg.value;
        donations[_campaignId][msg.sender] += msg.value;

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

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
}
