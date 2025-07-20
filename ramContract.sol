

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title RAM TECH Token Contract
 * @notice BEP20/ERC20 compatible token with advanced features for trading, fees, liquidity, and admin controls.
 * @dev All comments and error messages are in English as per project convention.
 */

// --- Interfaces ---

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @notice Provides information about the current execution context, including the sender of the transaction and its data.
 */
contract Context {
    constructor () { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @notice Ownable contract module provides basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
 */
contract Ownable is Context {
    // @notice The address of the contract owner. Once renounced, ownership cannot be recovered by any function.
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor () {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Renounces ownership of the contract. Owner will be set to zero address.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address of the new owner.
     */
   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @notice Prevents reentrant calls to a function.
 */
abstract contract nonReentrant {
    bool private _notEntered;

    constructor() {
        _notEntered = true;
    }

    /**
     * @notice Modifier to prevent reentrancy.
     */
    modifier nonReentrantGuard() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

/**
 * @title RAM_CEO_TOKEN
 * @notice Main token contract implementing BEP20/ERC20 with advanced features.
 */
contract RAM_CEO_TOKEN is Context, IBEP20, Ownable, nonReentrant {
    // --- Mappings ---
    mapping (address => uint256) private _balances; ///< Stores balances of each address
    mapping (address => mapping (address => uint256)) private _allowances; ///< Stores allowances
    mapping (address => bool) public isExempt; ///< Mapping for exempt addresses
   
    // --- Token Details ---
    uint256 public totalSupply; ///< Total supply of tokens
    uint8 public decimals; ///< Number of decimals
    string public symbol; ///< Token symbol
    string public name; ///< Token name

    // --- PancakeSwap Addresses ---
    address constant PANCAKESWAP_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; ///< PancakeSwap router address
    IPancakeRouter public immutable pancakeRouter; ///< PancakeSwap router interface
    address public pancakePair; ///< PancakeSwap pair address

    // --- Project Addresses ---
    address public marketingWallet = 0x05645AA747d63f5DD6819CD38fD45b69b7AB7168; ///< Marketing wallet address
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; ///< Wrapped BNB address
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD; ///< Burn address
    address constant restitutionAddress = 0xac3338322eA75eA4925AB02Fd547DD7A4228EC0F; ///< Address for restitution (corrected spelling)
    address constant admin = 0x7Bb2Dbb529771184207405c102E829d5d86c9457; ///< Admin address
    address public ca = 0x7Bb2Dbb529771184207405c102E829d5d86c9457; ///< Contract admin address

    /**
     * @notice The variable defined as a constant called "admin" is used to execute external functions even after the termination of the contract. However, the functions it can execute are by no means considered dangerous for token holders. These are functions that require constant control to ensure the proper functioning of the contract!
     *
     * Functions: setEnableInternalSwap, setAddressExempt, setSwapAmountNew, setBurnInternalStatus, setNewPair, setMarketingWallet, forceSwap
     * These functions do not represent a risk to investors, they only ensure that the contract can be managed in a healthy way. All other external functions can only be called by the contract's owner, who will resign a few hours after the start of trading.
     */

    // --- Trading Status ---
    bool public tradingEnabled; ///< Indicates if trading is enabled

    // --- Fee Values ---
    uint256 public buyFee = 5; ///< Buy fee percentage
    uint256 public sellFee = 5; ///< Sell fee percentage
    uint256 public burnFee = 1; ///< Burn fee percentage
    uint256 public liquidityFee = 1; ///< Liquidity fee percentage
    uint256 public denominator = 100; ///< Denominator for fee calculations

    // --- New Pair Management ---
    address[] public newPair; ///< List of additional pairs
    uint8 constant MAX_NEW_PAIRS = 20; ///< Maximum number of new pairs allowed

    // --- Swap and Supply Management ---
    uint256 public percentSwapAmount = 2; ///< Percentage of total supply to trigger swap
    
    /**
     * @notice Used only for the initial calculation of amountSwapTheBalance at deployment.
     * This value is not used in the token logic after construction; all supply logic uses totalSupply.
     */
    uint256 public total_Supply = 500000000 * 10 ** 18; ///< Total supply (500M), static reference for initial swap calculation
    uint256 public amountSwapTheBalance = (total_Supply * percentSwapAmount) / denominator; ///< Amount to trigger swap
    uint256 public stopBurnTx = 21000000 * 10 ** 18; ///< Limit for burning during transfers
    bool public enableInternalSwap; ///< Enable/disable internal swap
    bool public burnInternal; ///< Enable/disable internal burn

    // --- Dev Contact Info ---
    string constant TELEGRAM = "https://t.me/AbraaoOliveira47";
    string constant FACEBOOK = "https://www.facebook.com/xXPerfiladorXx";
    string constant WHATSAPP = "(74) 9 9194-3796";

    // --- DEV DATA --
    string constant DEV_NAME = " Abraao da Silva Oliveira";
    string constant DEV_CPF = "076.600.285-37";

    // --- Events ---
    event TradingStatusChanged(bool enabled); ///< Emitted when trading status changes
    event AddressExemptStatusChanged(address indexed account, bool exempt); ///< Emitted when exempt status changes
    event BuyFeeUpdated(uint256 newBuyFee); ///< Emitted when buy fee is updated
    event SellFeeUpdated(uint256 newSellFee); ///< Emitted when sell fee is updated
    event MarketingWalletUpdated(address indexed newMarketingWallet); ///< Emitted when marketing wallet is updated
    event LiquidityFeeUpdated(uint256 newLiquidityFee); ///< Emitted when liquidity fee is updated
    event BurnFeeUpdated(uint256 newBurnFee); ///< Emitted when burn fee is updated
    event TokensSwappedForBNB(uint256 tokensSwapped, uint256 bnbReceived); ///< Emitted when tokens are swapped for BNB
    event TokensBurned(uint256 amount); ///< Emitted when tokens are burned
    event LiquidityAdded(uint256 tokensAmount, uint256 bnbAmount); ///< Emitted when liquidity is added
    event MarketingFeesCollected(uint256 amount); ///< Emitted when marketing fees are collected
    event SwapFailed(string reason); ///< Emitted when swap fails
    event TransferFailed(string reason); ///< Emitted when transfer fails
    event WBNBWithdrawn(uint256 amount, address marketingWallet); ///< Emitted when BNB is withdrawn
    event TokenWithdrawn(address token, uint256 amount, address marketingWallet); ///< Emitted when tokens are withdrawn
    event enableInternalSwapUpdate(bool enableInternalSwap); ///< Emitted when internal swap status is updated
    event updateAmountSwap(uint256 amountSwapTheBalance); ///< Emitted when swap amount is updated
    event updateInternalBurn(bool burnInternal); ///< Emitted when internal burn status is updated
    event updateNewPair(address newPair); ///< Emitted when new pair is added
    
    /**
     * @notice Contract constructor. Initializes token details, PancakeSwap router, creates pair, and sets exempt addresses.
     */
    constructor() {
        name = "RAM TECH";
        symbol = "RAM";
        decimals = 18;
        totalSupply = 500000000 * 10 ** 18; // 500M of tokens
        _balances[msg.sender] = totalSupply;
        tradingEnabled = false; // Trading initially disabled
        enableInternalSwap = true; // The internal token swap for BNB is initially enabled.

        // Initialize PancakeSwap router
        buyFee = 5; // 5% buy fee
        sellFee = 5; // 5% sell fee
        burnInternal = false; // Initially false
        pancakeRouter = IPancakeRouter(PANCAKESWAP_ROUTER);
        
        // Create pair on PancakeSwap
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());

        // Defined exempt addresses
        isExempt[msg.sender] = true; // Owner is exempt
        isExempt[address(this)] = true; // Contract is exempt
        isExempt[marketingWallet] = true; // Marketing wallet is exempt
        isExempt[admin] = true; // Admin is exempt
        isExempt[restitutionAddress] = true; // Restitution address is exempt
        isExempt[burnAddress] = true; // Burn address is exempt
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external nonReentrantGuard override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external nonReentrantGuard override returns (bool) {
        require(spender != address(0), "BEP20: approve to the zero address");
        if(amount !=0 && _allowances[_msgSender()][spender] != 0) {
           //first approve must be zero
            _approve(_msgSender(), spender, 0);
        }
        
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external nonReentrantGuard override  returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }



    function increaseAllowance(address spender, uint256 addedValue) external  nonReentrantGuard returns  (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external nonReentrantGuard returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }


    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
    require(tradingEnabled || isExempt[sender] || isExempt[recipient], "Trading is not enabled");
    require(_balances[sender] > 0, "Insufficient balance");

    uint256 transferAmount = amount;

    // Buy (pair -> user): fee is taken from recipient (user)
    if ((sender == pancakePair || _isNewPair(sender)) && !isExempt[recipient]) {
        uint256 totalFee = (amount * buyFee) / denominator;
        uint256 burnAmount = (amount * burnFee) / denominator;
        uint256 liquidityAmount = (amount * liquidityFee) / denominator;
        uint256 marketingAmount = totalFee - burnAmount - liquidityAmount;

        // Transfer full amount from pair to user first
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        if (totalFee > 0) {
            // Deduct fees from recipient (user)
            if (burnAmount > 0 && totalSupply > stopBurnTx) {
                // Calculate the maximum amount that can be burned without going below the burn cap
                uint256 maxBurnAllowed = totalSupply - stopBurnTx;
                uint256 actualBurn = burnAmount > maxBurnAllowed ? maxBurnAllowed : burnAmount;
                if (actualBurn > 0) {
                    _balances[recipient] -= actualBurn;
                    totalSupply -= actualBurn;
                    emit TokensBurned(actualBurn);
                    emit Transfer(recipient, address(0), actualBurn);
                }
            }
            if (liquidityAmount > 0) {
                _balances[recipient] -= liquidityAmount;
                _balances[address(this)] += liquidityAmount;
                emit Transfer(recipient, address(this), liquidityAmount);
            }
            if (marketingAmount > 0) {
                _balances[recipient] -= marketingAmount;
                _balances[address(this)] += marketingAmount;
                emit MarketingFeesCollected(marketingAmount);
                emit Transfer(recipient, address(this), marketingAmount);
            }
            transferAmount = amount - totalFee;
        } else {
            transferAmount = amount;
        }
    }
    // Sell (user -> pair): fee is taken from sender (user)
    else if ((recipient == pancakePair || _isNewPair(recipient)) && !isExempt[sender]) {
        uint256 totalFee = (amount * sellFee) / denominator;
        uint256 burnAmount = (amount * burnFee) / denominator;
        uint256 liquidityAmount = (amount * liquidityFee) / denominator;
        uint256 marketingAmount = totalFee - burnAmount - liquidityAmount;

        if (totalFee > 0) {
            // Deduct fees from sender (user)
            if (burnAmount > 0 && totalSupply > stopBurnTx) {
                // Calculate the maximum amount that can be burned without going below the burn cap
                uint256 maxBurnAllowed = totalSupply - stopBurnTx;
                uint256 actualBurn = burnAmount > maxBurnAllowed ? maxBurnAllowed : burnAmount;
                if (actualBurn > 0) {
                    _balances[sender] -= actualBurn;
                    totalSupply -= actualBurn;
                    emit TokensBurned(actualBurn);
                    emit Transfer(sender, address(0), actualBurn);
                }
            }
            if (liquidityAmount > 0) {
                _balances[sender] -= liquidityAmount;
                _balances[address(this)] += liquidityAmount;
                emit Transfer(sender, address(this), liquidityAmount);
            }
            if (marketingAmount > 0) {
                _balances[sender] -= marketingAmount;
                _balances[address(this)] += marketingAmount;
                emit MarketingFeesCollected(marketingAmount);
                emit Transfer(sender, address(this), marketingAmount);
            }
            // Only subtract the net amount from sender after fees
            _balances[sender] -= (amount - totalFee);
            _balances[recipient] += (amount - totalFee);
            transferAmount = amount - totalFee;
        } else {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            transferAmount = amount;
        }
    }
    // Normal transfer (no fee)
    else {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        transferAmount = amount;
    }

    // Check if contract balance reached swap limit
    if (_balances[address(this)] >= amountSwapTheBalance && enableInternalSwap == true) {
        _swapTokensForBNB();
    }

    emit Transfer(sender, recipient, transferAmount);
}

    function _approve(address owner, address spender, uint256 amount) internal virtual  {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    

 function _swapTokensForBNB() internal {
    uint256 tokenBalance = _balances[address(this)];
    if (tokenBalance == 0) return;

    // Calculate the sum of all relevant fees (marketing fee is implicit)
    uint256 totalFee = liquidityFee + burnFee + (buyFee + sellFee - liquidityFee - burnFee);

    // Distribute tokens proportionally according to each fee
    uint256 liquidityTokens = (tokenBalance * liquidityFee) / totalFee;
    uint256 burnAmount = (tokenBalance * burnFee) / totalFee;

    // Half of the liquidity tokens go to the pair, half will be swapped for BNB
    uint256 tokensForPair = liquidityTokens / 2;
    uint256 tokensToSwap = tokenBalance - tokensForPair;

    // Approve the router to spend tokens
    _approve(address(this), address(PANCAKESWAP_ROUTER), tokenBalance);

    // Set up the swap path (token -> WBNB)
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WBNB;

    // Capture BNB balance before the swap
    uint256 bnbBefore = address(this).balance;

    try IPancakeRouter(PANCAKESWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokensToSwap - burnAmount,
        0,
        path,
        address(this),
        block.timestamp
    ) {
        // Calculate the actual BNB received from the swap
        uint256 bnbAfter = address(this).balance;
        uint256 bnbReceived = bnbAfter - bnbBefore;

        // Calculate the proportional BNB for liquidity
        uint256 bnbForLiquidity = (bnbReceived * tokensForPair) / (tokensToSwap - burnAmount);

        // Add liquidity if possible
        if (tokensForPair > 0 && bnbForLiquidity > 0) {
            IPancakeRouter(PANCAKESWAP_ROUTER).addLiquidityETH{value: bnbForLiquidity}(
                address(this),
                tokensForPair,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit LiquidityAdded(tokensForPair, bnbForLiquidity);
        }

        // Send the remaining BNB to the marketing wallet
        uint256 bnbForMarketing = address(this).balance;
        (bool success,) = marketingWallet.call{value: bnbForMarketing}("");
        if (!success) {
            emit TransferFailed("BNB transfer to marketing wallet failed");
        }

        // Burn tokens if required
        if (burnAmount > 0 && burnInternal == true && success == true) {
            // Calculate the maximum amount that can be burned without going below the burn cap
            uint256 maxBurnAllowed = totalSupply > stopBurnTx ? totalSupply - stopBurnTx : 0;
            uint256 actualBurn = burnAmount > maxBurnAllowed ? maxBurnAllowed : burnAmount;
            if (actualBurn > 0) {
                _balances[address(this)] -= actualBurn;
                totalSupply -= actualBurn;
                emit TokensBurned(actualBurn);
                emit Transfer(address(this), burnAddress, actualBurn);
            }
        }

        // Emit event with the actual swapped tokens and BNB received
        emit TokensSwappedForBNB(tokensToSwap - burnAmount, bnbReceived);
    } catch {
        emit SwapFailed("Swap tokens for BNB failed");
        return;
    }
}
    

    //owner functions

    function setTradingStatus(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        emit TradingStatusChanged(_enabled);
    }

    function setBuyFee(uint256 newBuyFee) external onlyOwner {
        require(newBuyFee <= 35, "Purchase rate higher than allowed!");
        buyFee = newBuyFee;
        emit BuyFeeUpdated(newBuyFee);
    }   

    function setSellFee(uint256 newSellFee) external onlyOwner {
        require(newSellFee <= 35, "Sales rate higher than allowed!");
        sellFee = newSellFee;
        emit SellFeeUpdated(newSellFee);
    }   

    

    function setLiquidityFee(uint256 newLiquidityFee) external onlyOwner {
        require(newLiquidityFee <= 10,"Liquidity rate above permitted!");
        liquidityFee = newLiquidityFee;
        emit LiquidityFeeUpdated(newLiquidityFee);
    }   

    function setBurnFee(uint256 newBurnFee) external onlyOwner {
        require(newBurnFee <= 5, "Burning rate above permitted!");
        burnFee = newBurnFee;
        emit BurnFeeUpdated(newBurnFee);
    }   

   
    //Admin functions
    function setEnableInternalSwap(bool _value) external{
    require(_msgSender() == admin, "Only the admin can set exemptions");
     enableInternalSwap= _value; 

     emit enableInternalSwapUpdate(_value);  
    }



 function setAddressExempt(address account, bool exempt) external  {
        require(_msgSender() == admin, "Only the admin can set exemptions");
        require(account != address(0), "Invalid address");
        require(account != PANCAKESWAP_ROUTER && account != pancakePair, "Address cannot be changed");
        isExempt[account] = exempt;
        emit AddressExemptStatusChanged(account, exempt);
    }

    function setSwapAmountNew(uint256 _newAmountSwap, bool _confirm)external{
        require(_msgSender() == admin, "Only the admin can set exemptions");
       require(_newAmountSwap > 0, "The amount cannot be zero!");
       require(_confirm, "You must confirm the change!");
       amountSwapTheBalance = _newAmountSwap;

       emit updateAmountSwap(_newAmountSwap);

}
function setBurnInternalStatus(bool _valueBurn)external{
    require(_msgSender() == admin, "Only the admin can set exemptions");
    burnInternal = _valueBurn;
    emit updateInternalBurn(_valueBurn);
}
    
function setNewPair(address _newPair) external {
    require(_msgSender() == admin, "Only the admin can set exemptions");
    require(_newPair != address(0), "Addresses cannot be the zero address!");
    require(newPair.length < MAX_NEW_PAIRS, "The list has already reached its maximum value!");

    // Check if the pair already exists
    for (uint256 i = 0; i < newPair.length; i++) {
        require(newPair[i] != _newPair, "Pair already exists in the list!");
    }

    newPair.push(_newPair);
    emit updateNewPair(_newPair);
}    

function setMarketingWallet(address newMarketingWallet) external{
        require(_msgSender() == admin, "Only the admin can set exemptions");
        require(newMarketingWallet != address(0), "Invalid Address!");
        marketingWallet = newMarketingWallet;
        emit MarketingWalletUpdated(newMarketingWallet);
    }    

function forceSwap(bool _confirm) external{
        require(_msgSender() == admin, "Only the admin can set exemptions");
        require(enableInternalSwap == true, "Error, internal swap disabled. Cannot force swap!");
        uint256 _contractBalance = _balances[address(this)];
        require(_contractBalance > 0, "Insufficient contract balance.");
        require(_confirm, "You must confirm this action.");
        _swapTokensForBNB();
    } 

   function withdrawNativeBNB() external nonReentrantGuard {
        require(_msgSender() == admin, "Only the admin can set exemptions");
        uint256 bnbBalance = address(this).balance;
        require(bnbBalance > 0, "No BNB to withdraw");
        
        (bool success,) = marketingWallet.call{value: bnbBalance}("");
        require(success, "BNB transfer failed");
        
        emit WBNBWithdrawn(bnbBalance, marketingWallet);
    }
    
    function withdrawTokens(address token) external nonReentrantGuard{
        require(_msgSender() == admin, "Only the admin can set exemptions");
        require(token != address(0), "Invalid token address");
        uint256 tokenBalance = IBEP20(token).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");
        
        bool success = IBEP20(token).transfer(restitutionAddress, tokenBalance);
        require(success, "Token transfer failed");
        
        emit TokenWithdrawn(token, tokenBalance, restitutionAddress);
    }

    function setNewCa(address _newCa) external{
        require(_msgSender() == admin, "Only the admin can set exemptions");
        ca = _newCa;
        
    }
     
     /**
      * @notice Burns tokens from the admin (ca) address. The minimum supply check (not burning below 21M tokens)
      * is NOT enforced here. It is the responsibility of the external contract calling this function to ensure
      * that the burn does not reduce the supply below the defined minimum (21M tokens).
      */
     function additionalBurnTokens(uint256 _amountBurn) external nonReentrantGuard{
        require(_msgSender() == ca, "Only the admin can set exemptions");
        require(_amountBurn > 0, "The amount cannot be zero!");

        // Check allowance
        uint256 allowance2 = IBEP20(address(this)).allowance(ca, address(this));
        require(allowance2 >= _amountBurn, "Insufficient allowance for burn");

        // Check balance
        uint256 adminBalance = IBEP20(address(this)).balanceOf(ca);
        require(adminBalance >= _amountBurn, "Insufficient balance for burn");

        bool success = IBEP20(address(this)).transferFrom(ca, address(this), _amountBurn);
        require(success, "Token transfer failed");

        _balances[address(this)] -= _amountBurn;
        totalSupply -= _amountBurn;
        emit TokensBurned(_amountBurn);
        emit Transfer(address(this), burnAddress, _amountBurn);
     }
    // Helper function to check if the address is a new pair.
    function _isNewPair(address account) internal  view returns  (bool) {
        for (uint256 i = 0; i < newPair.length; i++) {
            if (newPair[i] == account) {
                return true;
            }
        }
        return false;
    }

    
    function getOwner() external view override returns (address) {
        return owner;
    }

    // Add function to receive BNB
    receive() external payable {}
}
