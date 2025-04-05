// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofActivity
 * @dev Complete solution for Proof of Activity with integrated token
 */
contract ProofActivityTest {
    // === Token Basic Info ===
    string public name = "Activity Token";
    string public symbol = "ACT";
    uint8 public decimals = 18;
    
    // Token metadata URL with embedded image
    string public tokenURI = "PASTE_DATA_IMAGE_HERE";
    
    // === Activity System Constants ===
    uint256 public constant TOTAL_EPOCH_REWARD = 1_000_000 * 10**18; // 1 million tokens per epoch
    uint256 public constant MAX_SUPPLY = 365_000_000 * 10**18; // 365 million tokens max supply
    uint256 public constant EPOCH_DURATION = 30 minutes; // 30 minutes for testing
    
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
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    /**
     * @dev Internal function to spend allowance
     */
    function _spendAllowance(address _owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[_owner][spender];
        
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
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