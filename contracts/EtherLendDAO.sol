// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title EtherLend DAO
 * @notice A decentralized ETH lending protocol with DAO governance
 * @dev Users can supply ETH, borrow ETH based on collateral (60% LTV),
 *      and participate in governance voting using ELEND governance tokens.
 */

contract EtherLendDAO {
    // Governance Token
    string public constant name = "EtherLend Governance Token";
    string public constant symbol = "ELEND";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // Lending Data
    struct Account {
        uint256 depositBalance;
        uint256 borrowedBalance;
    }

    mapping(address => Account) public accounts;
    uint256 public constant collateralRatio = 60; // 60% LTV

    // DAO Proposal
    struct Proposal {
        string description;
        uint256 votes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event ProposalCreated(uint256 id, string description, uint256 deadline);
    event Voted(uint256 id, address indexed voter, uint256 votes);
    event ProposalExecuted(uint256 id);

    // ──────────────────────────────────────────────
    // Deposit & Borrow System
    // ──────────────────────────────────────────────
    function deposit() external payable {
        require(msg.value > 0, "Deposit value required");

        accounts[msg.sender].depositBalance += msg.value;

        // Mint governance tokens equal to deposit
        totalSupply += msg.value;
        balanceOf[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function maxBorrowable(address user) public view returns (uint256) {
        return (accounts[user].depositBalance * collateralRatio) / 100;
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Invalid borrow amount");
        require(maxBorrowable(msg.sender) >= accounts[msg.sender].borrowedBalance + amount, "Collateral insufficient");

        accounts[msg.sender].borrowedBalance += amount;
        payable(msg.sender).transfer(amount);

        emit Borrowed(msg.sender, amount);
    }

    function repay() external payable {
        require(msg.value > 0, "No repayment amount");
        require(accounts[msg.sender].borrowedBalance > 0, "Nothing to repay");

        accounts[msg.sender].borrowedBalance -= msg.value;
        emit Repaid(msg.sender, msg.value);
    }

    // ──────────────────────────────────────────────
    // DAO Governance
    // ──────────────────────────────────────────────
    function createProposal(string calldata description, uint256 votingDuration) external {
        require(balanceOf[msg.sender] > 0, "Governance token required to propose");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.description = description;
        p.deadline = block.timestamp + votingDuration;

        emit ProposalCreated(proposalCount, description, p.deadline);
    }

    function vote(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];

        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.voted[msg.sender], "Already voted");
        require(balanceOf[msg.sender] > 0, "No governance tokens");

        p.voted[msg.sender] = true;
        p.votes += balanceOf[msg.sender];

        emit Voted(proposalId, msg.sender, balanceOf[msg.sender]);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];

        require(block.timestamp >= p.deadline, "Voting not finished");
        require(!p.executed, "Already executed");

        p.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // ──────────────────────────────────────────────
    // View Functions
    // ──────────────────────────────────────────────
    function liquidityPool() external view returns (uint256) {
        return address(this).balance;
    }
}
