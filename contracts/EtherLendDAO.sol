Structs
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
    
    Events
    event MemberJoined(address indexed member, uint256 stakedAmount);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event LoanRequested(uint256 indexed loanId, address borrower, uint256 amount);
    event LoanApproved(uint256 indexed loanId);
    event LoanRepaid(uint256 indexed loanId, address borrower);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    Reward depositor with voting power if they're a member
        if (members[msg.sender].isActive) {
            members[msg.sender].votingPower += msg.value / 0.01 ether;
        }
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    Return collateral
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
// 
End
// 
