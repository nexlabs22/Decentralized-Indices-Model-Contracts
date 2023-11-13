// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../proposable/ProposableOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./TokenInterface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

/// @title Index Token
/// @author NEX Labs Protocol
/// @notice The main token contract for Index Token (NEX Labs Protocol)
/// @dev This contract uses an upgradeable pattern
contract IndexToken is
    ContextUpgradeable,
    ERC20Upgradeable,
    ProposableOwnableUpgradeable,
    PausableUpgradeable,
    TokenInterface
{
    
    uint256 internal constant SCALAR = 1e20;

    // Inflation rate (per day) on total supply, to be accrued to the feeReceiver.
    uint256 public feeRatePerDayScaled;

    // Most recent timestamp when fee was accured.
    uint256 public feeTimestamp;

    // Address that can claim fees accrued.
    address public feeReceiver;

    // Address that can publish a new methodology.
    address public methodologist;

    // Address that has privilege to mint and burn. It will be Controller and Admin to begin.
    address public minter;

    string public methodology;

    uint256 public supplyCeiling;

    mapping(address => bool) public isRestricted;

    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IWETH public weth = IWETH(WETH9);
    IQuoter public quoter = IQuoter(QUOTER);

    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "IndexToken: caller is not the methodologist");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "IndexToken: caller is not the minter");
        _;
    }

    
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _feeRatePerDayScaled,
        address _feeReceiver,
        uint256 _supplyCeiling
    ) external override initializer {
        require(_feeReceiver != address(0));

        __Ownable_init();
        __Pausable_init();
        __ERC20_init(tokenName, tokenSymbol);
        __Context_init();

        feeRatePerDayScaled = _feeRatePerDayScaled;
        feeReceiver = _feeReceiver;
        supplyCeiling = _supplyCeiling;
        feeTimestamp = block.timestamp;
    }

   /**
    * @dev The contract's fallback function that does not allow direct payments to the contract.
    * @notice Prevents users from sending ether directly to the contract by reverting the transaction.
    */
    receive() external payable {
        // revert DoNotSendFundsDirectlyToTheContract();
    }
    
    /// @notice External mint function
    /// @dev Mint function can only be called externally by the controller
    /// @param to address
    /// @param amount uint256
    function mint(address to, uint256 amount) external override whenNotPaused onlyMinter {
        require(totalSupply() + amount <= supplyCeiling, "will exceed supply ceiling");
        require(!isRestricted[to], "to is restricted");
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        _mintToFeeReceiver();
        _mint(to, amount);
    }

    /// @notice External burn function
    /// @dev burn function can only be called externally by the controller
    /// @param from address
    /// @param amount uint256
    function burn(address from, uint256 amount) external override whenNotPaused onlyMinter {
        require(!isRestricted[from], "from is restricted");
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        _mintToFeeReceiver();
        _burn(from, amount);
    }

    function _mintToFeeReceiver() internal {
        // total number of days elapsed
        uint256 _days = (block.timestamp - feeTimestamp) / 1 days;

        if (_days >= 1) {
            uint256 initial = totalSupply();
            uint256 supply = initial;
            uint256 _feeRate = feeRatePerDayScaled;

            for (uint256 i; i < _days; ) {
                supply += ((supply * _feeRate) / SCALAR);
                unchecked {
                    ++i;
                }
            }
            uint256 amount = supply - initial;
            feeTimestamp += 1 days * _days;
            _mint(feeReceiver, amount);

            emit MintFeeToReceiver(feeReceiver, block.timestamp, totalSupply(), amount);
        }
    }

    /// @notice Expands supply and mints fees to fee reciever
    /// @dev Can only be called by the owner externally,
    /// @dev _mintToFeeReciver is the internal function and is called after each supply/rate change
    function mintToFeeReceiver() external override onlyOwner {
        _mintToFeeReceiver();
    }

    
    /// @notice Only owner function for setting the methodologist
    /// @param _methodologist address
    function setMethodologist(address _methodologist) external override onlyOwner {
        require(_methodologist != address(0));
        methodologist = _methodologist;
        emit MethodologistSet(_methodologist);
    }

    /// @notice Callable only by the methodoligst to store on chain data about the underlying weight of the token
    /// @param _methodology string
    function setMethodology(string memory _methodology) external override onlyMethodologist {
        methodology = _methodology;
        emit MethodologySet(_methodology);
    }

    /// @notice Ownable function to set the fee rate
    /// @dev Given the annual fee rate this function sets and calculates the rate per second
    /// @param _feeRatePerDayScaled uint256
    function setFeeRate(uint256 _feeRatePerDayScaled) external override onlyOwner {
        _mintToFeeReceiver();
        feeRatePerDayScaled = _feeRatePerDayScaled;
        emit FeeRateSet(_feeRatePerDayScaled);
    }

    /// @notice Ownable function to set the receiver
    /// @param _feeReceiver address
    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        require(_feeReceiver != address(0));
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(_feeReceiver);
    }

    /// @notice Ownable function to set the contract that controls minting
    /// @param _minter address
    function setMinter(address _minter) external override onlyOwner {
        require(_minter != address(0));
        minter = _minter;
        emit MinterSet(_minter);
    }

    /// @notice Ownable function to set the limit at which the total supply cannot exceed
    /// @param _supplyCeiling uint256
    function setSupplyCeiling(uint256 _supplyCeiling) external override onlyOwner {
        supplyCeiling = _supplyCeiling;
        emit SupplyCeilingSet(_supplyCeiling);
    }

    
    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    
    /// @notice Compliance feature to blacklist bad actors
    /// @dev Negates current restriction state
    /// @param who address
    function toggleRestriction(address who) external override onlyOwner {
        isRestricted[who] = !isRestricted[who];
        emit ToggledRestricted(who, isRestricted[who]);
    }

    
    /// @notice Overriden ERC20 transfer to include restriction
    /// @param to address
    /// @param amount uint256
    /// @return bool
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        require(!isRestricted[to], "to is restricted");

        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Overriden ERC20 transferFrom to include restriction
    /// @param from address
    /// @param to address
    /// @param amount uint256
    /// @return bool
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        require(!isRestricted[to], "to is restricted");
        require(!isRestricted[from], "from is restricted");

        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _swapSingle(address tokenIn, address tokenOut, uint amountIn) internal returns(uint){
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        uint amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }


    function mintToken(address tokenIn, uint amountIn) public {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        IERC20(tokenIn).approve(address(swapRouter), amountIn);
        _swapSingle(tokenIn, WETH9, amountIn);

        mint(msg.sender, amountIn);
    }

    function burnToken(address tokenIn, uint amountIn) public {
        burn(msg.sender, amountIn);

        IERC20(tokenIn).approve(address(swapRouter), amountIn);
        _swapSingle(WETH9, tokenIn, amountIn);

    }



    
}