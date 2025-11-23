// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EtherLend DAO
 * @dev Decentralized lending platform governed by DAO members
 */
contract EtherLendDAO {
    
    // Structs
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        address recipient;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    struct LoanRequest {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 collateral;
        bool approved;
        bool repaid;
        uint256 timestamp;
    }
    
    struct Member {
        uint256 votingPower;
        uint256 stakedAmount;
        uint256 joinTimestamp;
        bool isActive;
    }
    
    // State variables
    address public admin;
    uint256 public proposalCount;
    uint256 public loanRequestCount;
    uint256 public treasuryBalance;
    uint256 public minStakeAmount = 0.1 ether;
    uint256 public proposalDuration = 7 days;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => LoanRequest) public loanRequests;
    mapping(address => Member) public members;
    
    // Events
    event MemberJoined(address indexed member, uint256 stakedAmount);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event LoanRequested(uint256 indexed loanId, address borrower, uint256 amount);
    event LoanApproved(uint256 indexed loanId);
    event LoanRepaid(uint256 indexed loanId, address borrower);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    // Modifiers
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not a DAO member");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Join DAO by staking ETH
     */
    function joinDAO() external payable {
        require(msg.value >= minStakeAmount, "Insufficient stake amount");
        require(!members[msg.sender].isActive, "Already a member");
        
        members[msg.sender] = Member({
            votingPower: msg.value / 0.01 ether,
            stakedAmount: msg.value,
            joinTimestamp: block.timestamp,
            isActive: true
        });
        
        treasuryBalance += msg.value;
        
        emit MemberJoined(msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 2: Create governance proposal
     */
    function createProposal(
        string memory _description,
        uint256 _amount,
        address _recipient
    ) external onlyMember returns (uint256) {
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.recipient = _recipient;
        newProposal.deadline = block.timestamp + proposalDuration;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCount, msg.sender, _description);
        
        return proposalCount;
    }
    
    /**
     * @dev Core Function 3: Vote on proposals
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votePower = members[msg.sender].votingPower;
        
        if (_support) {
            proposal.votesFor += votePower;
        } else {
            proposal.votesAgainst += votePower;
        }
        
        proposal.hasVoted[msg.sender] = true;
        
        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }
    
    /**
     * @dev Core Function 4: Request loan from DAO treasury
     */
    function requestLoan(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _duration
    ) external payable onlyMember returns (uint256) {
        require(msg.value >= _amount / 2, "Collateral must be at least 50%");
        require(_amount <= treasuryBalance, "Insufficient treasury funds");
        
        loanRequestCount++;
        
        loanRequests[loanRequestCount] = LoanRequest({
            id: loanRequestCount,
            borrower: msg.sender,
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            collateral: msg.value,
            approved: false,
            repaid: false,
            timestamp: block.timestamp
        });
        
        emit LoanRequested(loanRequestCount, msg.sender, _amount);
        
        return loanRequestCount;
    }
    
    /**
     * @dev Core Function 5: Deposit funds to DAO treasury
     */
    function depositToTreasury() external payable {
        require(msg.value > 0, "Must deposit some ETH");
        
        treasuryBalance += msg.value;
        
        // Reward depositor with voting power if they're a member
        if (members[msg.sender].isActive) {
            members[msg.sender].votingPower += msg.value / 0.01 ether;
        }
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    // Additional helper functions
    
    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.deadline, "Voting still ongoing");
        require(!proposal.executed, "Already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");
        
        proposal.executed = true;
        
        if (proposal.amount > 0 && proposal.recipient != address(0)) {
            require(treasuryBalance >= proposal.amount, "Insufficient funds");
            treasuryBalance -= proposal.amount;
            payable(proposal.recipient).transfer(proposal.amount);
        }
        
        emit ProposalExecuted(_proposalId, true);
    }
    
    function approveLoan(uint256 _loanId) external onlyAdmin {
        LoanRequest storage loan = loanRequests[_loanId];
        
        require(!loan.approved, "Loan already approved");
        require(treasuryBalance >= loan.amount, "Insufficient treasury");
        
        loan.approved = true;
        treasuryBalance -= loan.amount;
        
        payable(loan.borrower).transfer(loan.amount);
        
        emit LoanApproved(_loanId);
    }
    
    function repayLoan(uint256 _loanId) external payable {
        LoanRequest storage loan = loanRequests[_loanId];
        
        require(msg.sender == loan.borrower, "Not the borrower");
        require(loan.approved, "Loan not approved");
        require(!loan.repaid, "Already repaid");
        
        uint256 interest = (loan.amount * loan.interestRate) / 100;
        uint256 totalRepayment = loan.amount + interest;
        
        require(msg.value >= totalRepayment, "Insufficient repayment");
        
        loan.repaid = true;
        treasuryBalance += totalRepayment;
        
        // Return collateral
        payable(loan.borrower).transfer(loan.collateral);
        
        emit LoanRepaid(_loanId, msg.sender);
    }
    
    function getMemberInfo(address _member) external view returns (
        uint256 votingPower,
        uint256 stakedAmount,
        uint256 joinTimestamp,
        bool isActive
    ) {
        Member memory member = members[_member];
        return (
            member.votingPower,
            member.stakedAmount,
            member.joinTimestamp,
            member.isActive
        );
    }
    
    function getProposalVotes(uint256 _proposalId) external view returns (
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }
    
    receive() external payable {
        treasuryBalance += msg.value;
    }
}