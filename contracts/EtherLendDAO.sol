// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title EtherLend DAO
 * @notice Governance contract allowing token holders to create, vote and execute proposals.
 * @dev This is a template. Add safety checks, timelock and lending integrations as needed.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
}

contract EtherLendToken {
    string public name = "EtherLend Governance Token";
    string public symbol = "ELT";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    address public dao;

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    constructor(address _dao) {
        dao = _dao;
    }

    function mint(address to, uint256 amount) external onlyDAO {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Bal < amount");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Bal < amount");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract EtherLendDAO {
    // ----------------------------------------------------------
    // STRUCTS
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // STATE VARIABLES
    // ----------------------------------------------------------
    EtherLendToken public token;
    uint256 public constant VOTING_DURATION = 20000;  // ~3 days on Ethereum
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    address public treasury;
    address public owner;

    // ----------------------------------------------------------
    // EVENTS
    // ----------------------------------------------------------
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        string description,
        address target,
        uint256 value
    );
    event Vote(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event Executed(uint256 indexed id);

    // ----------------------------------------------------------
    // MODIFIERS
    // ----------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ----------------------------------------------------------
    // CONSTRUCTOR
    // ----------------------------------------------------------
    constructor() {
        owner = msg.sender;

        // Create governance token and give DAO minting rights
        token = new EtherLendToken(address(this));

        // Mint initial tokens to deployer (bootstrap)
        token.mint(msg.sender, 1_000_000 ether);

        treasury = address(this);
    }

    // ----------------------------------------------------------
    // DAO CORE
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // TREASURY FUNCTIONS
    // ----------------------------------------------------------
    receive() external payable {}

    function withdrawTreasury(address to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough ETH");
        payable(to).transfer(amount);
    }
}
