----------------------------------------------------------
    ----------------------------------------------------------
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteYes;
        uint256 voteNo;
        uint256 endBlock;
        bool executed;
        address target;
        uint256 value;
        bytes callData;
    }

    STATE VARIABLES
    ~3 days on Ethereum
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    address public treasury;
    address public owner;

    EVENTS
    ----------------------------------------------------------
    ----------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    CONSTRUCTOR
    Create governance token and give DAO minting rights
        token = new EtherLendToken(address(this));

        ----------------------------------------------------------
    ----------------------------------------------------------
    function createProposal(
        string calldata description,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (uint256) {
        require(token.balanceOf(msg.sender) > 0, "No voting power");

        proposalCount++;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            voteYes: 0,
            voteNo: 0,
            endBlock: block.number + VOTING_DURATION,
            executed: false,
            target: target,
            value: value,
            callData: callData
        });

        emit ProposalCreated(proposalCount, msg.sender, description, target, value);
        return proposalCount;
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.number < p.endBlock, "Voting ended");
        require(!voted[id][msg.sender], "Already voted");

        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        voted[id][msg.sender] = true;

        if (support) p.voteYes += weight;
        else p.voteNo += weight;

        emit Vote(id, msg.sender, support, weight);
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(block.number >= p.endBlock, "Voting still active");
        require(!p.executed, "Already executed");
        require(p.voteYes > p.voteNo, "Proposal rejected");

        p.executed = true;

        (bool success, ) = p.target.call{value: p.value}(p.callData);
        require(success, "Execution failed");

        emit Executed(id);
    }

    TREASURY FUNCTIONS
    // ----------------------------------------------------------
    receive() external payable {}

    function withdrawTreasury(address to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough ETH");
        payable(to).transfer(amount);
    }
}
// 
Contract End
// 
