// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofActivityToken
 * @dev Complete solution for Proof of Activity with integrated token
 */
contract ProofActivity {
    // === Token Basic Info ===
    string public name = "Activity Token";
    string public symbol = "ACT";
    uint8 public decimals = 18;
    
    // Token metadata URL with embedded image
    string public tokenURI = "data:image/webp;base64,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";
    
    // === Activity System Constants ===
    uint256 public constant TOTAL_EPOCH_REWARD = 1_000_000 * 10**18; // 1 million tokens per epoch
    uint256 public constant MAX_SUPPLY = 365_000_000 * 10**18; // 365 million tokens max supply
    uint256 public constant EPOCH_DURATION = 1 days; // 24 hours
    
    // === Burn Fee Constants ===
    uint256 public burnFeePercent = 1; // 1% burn fee on transfers
    
    // === State Variables ===
    bool public paused;
    uint256 public totalTxCount;
    uint256 public epochStartTime;
    uint256 public totalMinted;
    uint256 private _totalSupply;
    address public owner;
    
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
        uint256 burnFeePercent;
        EpochStats[] epochs;
    }

    // === Events for Token ===
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TokenURIUpdated(string newURI);
    
    // === Events for Activity System ===
    event UserCounterCreated(address user, uint256 epoch);
    event UserCounterIncremented(address user, uint256 epoch, uint256 newCount);
    event UserCounterRegistered(address user, uint256 epoch, uint256 count);
    event RewardClaimed(address user, uint256 epoch, uint256 amount);
    event DirectorPaused();
    event DirectorResumed();
    event TokensBurned(address from, uint256 amount, string reason);
    event BurnFeeUpdated(uint256 newFee);
    event MaxSupplyReached();

    // === Constructor ===
    constructor(uint256 initialSupply) {
        epochStartTime = block.timestamp;
        paused = true; // Start paused
        owner = msg.sender;
        totalMinted = 0;
        
        // Mint initial supply to the owner if specified
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
            totalMinted = initialSupply;
        }
    }

    // === Modifiers ===
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "System is paused");
        _;
    }

    modifier onlyCorrectEpoch(uint256 epoch) {
        require(epoch == getCurrentEpoch(), "Wrong epoch");
        _;
    }
    
    // === ERC20 Token Functions ===
    
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
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Returns the allowance given to a spender by an owner
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev Approves the given address to spend the specified amount of tokens
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens from one address to another using allowance
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Burns tokens from the caller
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    /**
     * @dev Burns tokens from an account that has given allowance
     */
    function burnFrom(address account, uint256 amount) external returns (bool) {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
        return true;
    }
    
    /**
     * @dev Transfer tokens with burn fee
     * A percentage of tokens will be burned during transfer
     */
    function transferWithBurn(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate burn amount and remaining amount
        uint256 burnAmount = (amount * burnFeePercent) / 100;
        uint256 transferAmount = amount - burnAmount;
        
        // Burn tokens
        _burn(msg.sender, burnAmount);
        
        // Transfer remaining tokens
        _transfer(msg.sender, to, transferAmount);
        
        emit TokensBurned(msg.sender, burnAmount, "Transfer fee burn");
        return true;
    }
    
    // === Activity System Functions ===
    
    /**
     * @dev Create a new user counter for the current epoch
     */
    function newUserCounter() external notPaused {
        uint256 currentEpoch = getCurrentEpoch();
        UserCounter storage counter = userCounters[msg.sender][currentEpoch];
        
        // Only initialize if not already created
        if (counter.txCount == 0) {
            counter.epoch = currentEpoch;
            counter.txCount = 1; // Count this transaction
            counter.registered = false;
            counter.claimed = false;
            
            emit UserCounterCreated(msg.sender, currentEpoch);
        }
    }

    /**
     * @dev Increment the user counter for the current epoch
     */
    function incrementUserCounter() external notPaused onlyCorrectEpoch(getCurrentEpoch()) {
        uint256 currentEpoch = getCurrentEpoch();
        UserCounter storage counter = userCounters[msg.sender][currentEpoch];
        
        require(counter.txCount > 0, "Counter not initialized");
        counter.txCount += 1;
        
        emit UserCounterIncremented(msg.sender, currentEpoch, counter.txCount);
    }

    /**
     * @dev Register a user counter for the previous epoch
     * Can only be called during the epoch after the counter's epoch
     */
    function registerUserCounter() external notPaused {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 previousEpoch = currentEpoch - 1;
        
        UserCounter storage counter = userCounters[msg.sender][previousEpoch];
        
        require(counter.txCount > 0, "Counter not initialized");
        require(!counter.registered, "Counter already registered");
        require(!userRegisteredInEpoch[previousEpoch][msg.sender], "Already registered for this epoch");
        
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
    function claimUserReward(uint256 epochToClaim) external {
        uint256 currentEpoch = getCurrentEpoch();
        require(epochToClaim <= currentEpoch - 2, "Epoch too recent");
        
        UserCounter storage counter = userCounters[msg.sender][epochToClaim];
        
        require(counter.registered, "Counter not registered");
        require(!counter.claimed, "Rewards already claimed");
        
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
        
        // Mark as claimed
        counter.claimed = true;
        
        // Mint tokens directly to the user
        _mint(msg.sender, userReward);
        
        // Update total minted
        totalMinted += userReward;
        
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
            burnFeePercent: burnFeePercent,
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
     * @dev Transfer ownership of the contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    /**
     * @dev Update burn fee percentage
     */
    function setBurnFeePercent(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fee cannot exceed 10%");
        burnFeePercent = newFee;
        emit BurnFeeUpdated(newFee);
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
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Internal function to approve spending
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev Internal function to spend allowance
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
    /**
     * @dev Internal function to mint tokens
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to zero address");
        
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Internal function to burn tokens
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from zero address");
        
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        
        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }
}