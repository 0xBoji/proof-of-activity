// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofActivity
 * @dev Improved solution for Proof of Activity with integrated token
 * Enhanced with security improvements and optimizations
 */
contract ProofActivity {
    // === Token Basic Info ===
    string public name = "MOONAD";
    string public symbol = "MOONAD";
    uint8 public constant DECIMALS = 18;
    string public tokenURI = "https://i.postimg.cc/63LY8Sw-t/Screenshot-2025-04-05-at-21-46-56.png";
    
    // === Activity System Constants ===
    uint256 public constant TOTAL_EPOCH_REWARD = 1_000_000 * 10**18; // 1 million tokens per epoch
    uint256 public constant MAX_SUPPLY = 365_000_000 * 10**18; // 365 million tokens max supply
    uint256 public constant EPOCH_DURATION = 1 days; // 24 hours
    uint256 public constant MAX_TX_PER_USER_EPOCH = 10000; // Limit transactions per user per epoch
    
    // === State Variables ===
    bool public paused;
    uint256 public totalTxCount;
    uint256 public immutable epochStartTime;
    uint256 public totalMinted;
    uint256 private _totalSupply;
    address public owner;
    address public pendingOwner;
    bool private _reentrancyLock;
    
    // === Mappings for Token ===
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // === Mappings for Activity System ===
    mapping(uint256 => EpochCounter) public epochCounters;
    mapping(uint256 => mapping(address => bool)) public userRegisteredInEpoch;
    mapping(address => mapping(uint256 => UserCounter)) public userCounters;

    // === Structs ===
    struct EpochCounter {
        uint256 epoch;
        uint256 txCount;
        mapping(address => uint256) userCounts;
        mapping(address => bool) userRegistered;
    }

    struct UserCounter {
        uint256 epoch;
        uint256 txCount;
        bool registered;
        bool claimed;
    }

    struct EpochStats {
        uint256 epoch;
        uint256 txCount;
    }

    struct Stats {
        uint256 currentEpoch;
        bool paused;
        uint256 txCount;
        uint256 totalRemainingRewards;
        uint256 totalMinted;
        uint256 maxSupply;
        uint256 totalSupply;
        EpochStats[] epochs;
    }

    // === Events ===
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokenURIUpdated(string newURI);
    event UserCounterCreated(address indexed user, uint256 indexed epoch, uint256 txCount);
    event UserCounterIncremented(address indexed user, uint256 indexed epoch, uint256 newCount);
    event UserCounterRegistered(address indexed user, uint256 indexed epoch, uint256 count);
    event RewardClaimed(address indexed user, uint256 indexed epoch, uint256 amount);
    event DirectorPaused();
    event DirectorResumed();
    event MaxSupplyReached();
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // === Custom Errors ===
    error Paused();
    error NotOwner();
    error AlreadyInitialized();
    error ZeroAddress();
    error InvalidEpoch();
    error CounterNotInitialized();
    error AlreadyRegistered();
    error NotRegistered();
    error AlreadyClaimed();
    error EpochTooRecent();
    error MaxSupplyExceeded();
    error InsufficientBalance();
    error InsufficientAllowance();
    error TransferFailed();
    error MaxTxPerEpochExceeded();
    error ReentrancyGuard();

    // === Constructor ===
    constructor() {
        epochStartTime = block.timestamp;
        paused = true; // Start paused
        owner = msg.sender;
        totalMinted = 0;
    }

    // === Modifiers ===
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyCorrectEpoch(uint256 epoch) {
        if (epoch != getCurrentEpoch()) revert InvalidEpoch();
        _;
    }
    
    modifier nonReentrant() {
        if (_reentrancyLock) revert ReentrancyGuard();
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    // === ERC20 Token Functions ===
    
    /**
     * @dev Returns the token decimals
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }
    
    /**
     * @dev Returns the total token supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the balance of the given account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Transfers tokens to the specified address
     */
    function transfer(address to, uint256 amount) external nonReentrant returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Returns the allowance given to a spender by an owner
     */
    function allowance(address _owner, address spender) external view returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    /**
     * @dev Approves the given address to spend the specified amount of tokens
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Safe approve that checks current allowance first
     */
    function safeApprove(address spender, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        if (currentAllowance != 0) {
            _approve(msg.sender, spender, 0);
        }
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Increases the allowance given to a spender
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    /**
     * @dev Decreases the allowance given to a spender
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        if (currentAllowance < subtractedValue) {
            revert InsufficientAllowance();
        }
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    /**
     * @dev Transfers tokens from one address to another using allowance
     */
    function transferFrom(address from, address to, uint256 amount) external nonReentrant returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    // === Activity System Functions ===
    
    /**
     * @dev Create a new user counter for the current epoch
     */
    function newUserCounter() external notPaused nonReentrant {
        uint256 currentEpoch = getCurrentEpoch();
        UserCounter storage counter = userCounters[msg.sender][currentEpoch];
        
        // Only initialize if not already created
        if (counter.txCount == 0) {
            counter.epoch = currentEpoch;
            counter.txCount = 1; // Count this transaction
            counter.registered = false;
            counter.claimed = false;
            
            emit UserCounterCreated(msg.sender, currentEpoch, 1);
        }
    }

    /**
     * @dev Increment the user counter for the current epoch
     */
    function incrementUserCounter() external notPaused onlyCorrectEpoch(getCurrentEpoch()) nonReentrant {
        uint256 currentEpoch = getCurrentEpoch();
        UserCounter storage counter = userCounters[msg.sender][currentEpoch];
        
        if (counter.txCount == 0) revert CounterNotInitialized();
        if (counter.txCount >= MAX_TX_PER_USER_EPOCH) revert MaxTxPerEpochExceeded();
        
        counter.txCount += 1;
        
        emit UserCounterIncremented(msg.sender, currentEpoch, counter.txCount);
    }

    /**
     * @dev Register a user counter for the previous epoch
     * Can only be called during the epoch after the counter's epoch
     */
    function registerUserCounter() external notPaused nonReentrant {
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch == 0) revert InvalidEpoch();
        
        uint256 previousEpoch = currentEpoch - 1;
        
        UserCounter storage counter = userCounters[msg.sender][previousEpoch];
        
        if (counter.txCount == 0) revert CounterNotInitialized();
        if (counter.registered) revert AlreadyRegistered();
        if (userRegisteredInEpoch[previousEpoch][msg.sender]) revert AlreadyRegistered();
        
        // Mark as registered
        counter.registered = true;
        userRegisteredInEpoch[previousEpoch][msg.sender] = true;
        
        // Update epoch counter
        EpochCounter storage epochCounter = epochCounters[previousEpoch];
        epochCounter.epoch = previousEpoch;
        epochCounter.userCounts[msg.sender] = counter.txCount;
        epochCounter.txCount += counter.txCount;
        totalTxCount += counter.txCount;
        
        emit UserCounterRegistered(msg.sender, previousEpoch, counter.txCount);
    }

    /**
     * @dev Claim rewards for a registered user counter
     * Can only be called from the 2nd epoch after the counter's epoch
     */
    function claimUserReward(uint256 epochToClaim) external nonReentrant {
        uint256 currentEpoch = getCurrentEpoch();
        if (epochToClaim > currentEpoch - 2) revert EpochTooRecent();
        
        UserCounter storage counter = userCounters[msg.sender][epochToClaim];
        
        if (!counter.registered) revert NotRegistered();
        if (counter.claimed) revert AlreadyClaimed();
        
        EpochCounter storage epochCounter = epochCounters[epochToClaim];
        uint256 userTxs = epochCounter.userCounts[msg.sender];
        
        // Check if we've reached max supply
        if (totalMinted >= MAX_SUPPLY) {
            emit MaxSupplyReached();
            return;
        }
        
        // Calculate reward proportional to transaction count
        uint256 userReward = 0;
        if (epochCounter.txCount > 0) {
            userReward = (TOTAL_EPOCH_REWARD * userTxs) / epochCounter.txCount;
        }
        
        // Ensure we don't exceed MAX_SUPPLY
        if (totalMinted + userReward > MAX_SUPPLY) {
            userReward = MAX_SUPPLY - totalMinted;
        }
        
        // Mark as claimed before state changes
        counter.claimed = true;
        
        // Update total minted first
        totalMinted += userReward;
        
        // Mint tokens directly to the user
        _mint(msg.sender, userReward);
        
        emit RewardClaimed(msg.sender, epochToClaim, userReward);
    }
    
    // === View Functions ===
    
    /**
     * @dev Get current epoch number
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - epochStartTime) / EPOCH_DURATION;
    }
    
    /**
     * @dev Get time remaining in current epoch
     */
    function getEpochTimeRemaining() public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 nextEpochStart = epochStartTime + ((currentEpoch + 1) * EPOCH_DURATION);
        return nextEpochStart - block.timestamp;
    }
    
    /**
     * @dev Get stats for specific epochs
     */
    function getStatsForEpochs(uint256[] calldata epochNumbers) external view returns (Stats memory) {
        EpochStats[] memory epochStats = new EpochStats[](epochNumbers.length);
        
        for (uint256 i = 0; i < epochNumbers.length; i++) {
            uint256 epochNumber = epochNumbers[i];
            uint256 txCount = 0;
            
            // Get tx count for this epoch if it exists
            if (epochCounters[epochNumber].epoch == epochNumber) {
                txCount = epochCounters[epochNumber].txCount;
            }
            
            epochStats[i] = EpochStats({
                epoch: epochNumber,
                txCount: txCount
            });
        }
        
        return Stats({
            currentEpoch: getCurrentEpoch(),
            paused: paused,
            txCount: totalTxCount,
            totalRemainingRewards: MAX_SUPPLY - totalMinted,
            totalMinted: totalMinted,
            maxSupply: MAX_SUPPLY,
            totalSupply: _totalSupply,
            epochs: epochStats
        });
    }
    
    /**
     * @dev Get stats for recent epochs
     */
    function getStatsForRecentEpochs(uint256 count) external view returns (Stats memory) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 actualCount = count;
        
        if (count > currentEpoch) {
            actualCount = currentEpoch;
        }
        
        uint256[] memory epochNumbers = new uint256[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            epochNumbers[i] = currentEpoch - (i + 1);
        }
        
        return this.getStatsForEpochs(epochNumbers);
    }
    
    /**
     * @dev Get user counter info
     */
    function getUserCounterInfo(address user, uint256 epoch) external view returns (uint256 txCount, bool registered, bool claimed) {
        UserCounter storage counter = userCounters[user][epoch];
        return (counter.txCount, counter.registered, counter.claimed);
    }

    /**
     * @dev Get remaining supply that can be minted
     */
    function getRemainingSupply() external view returns (uint256) {
        if (totalMinted >= MAX_SUPPLY) {
            return 0;
        }
        return MAX_SUPPLY - totalMinted;
    }
    
    // === Admin Functions ===
    
    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        paused = true;
        emit DirectorPaused();
    }
    
    /**
     * @dev Resume the contract
     */
    function resume() external onlyOwner {
        paused = false;
        emit DirectorResumed();
    }
    
    /**
     * @dev Start the process of transferring ownership of the contract
     * Implements a 2-step ownership transfer for security
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }
    
    /**
     * @dev Accept ownership transfer
     * Only the pending owner can complete the transfer
     */
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotOwner();
        
        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        
        emit OwnershipTransferred(oldOwner, owner);
    }
    
    /**
     * @dev Sets token URI for metadata (including image)
     */
    function setTokenURI(string memory newURI) external onlyOwner {
        tokenURI = newURI;
        emit TokenURIUpdated(newURI);
    }
    
    // === Internal Token Functions ===
    
    /**
     * @dev Internal function to transfer tokens
     */
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) revert InsufficientBalance();
        
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Internal function to approve spending
     */
    function _approve(address _owner, address spender, uint256 amount) internal {
        if (_owner == address(0) || spender == address(0)) revert ZeroAddress();
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    /**
     * @dev Internal function to spend allowance
     */
    function _spendAllowance(address _owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[_owner][spender];
        
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
    
    /**
     * @dev Internal function to mint tokens
     */
    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        
        emit Transfer(address(0), account, amount);
    }
}