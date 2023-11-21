// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../proposable/ProposableOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./TokenInterface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "../libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

/// @title Index Token
/// @author NEX Labs Protocol
/// @notice The main token contract for Index Token (NEX Labs Protocol)
/// @dev This contract uses an upgradeable pattern
contract IndexToken is
    ChainlinkClient,
    ContextUpgradeable,
    ERC20Upgradeable,
    ProposableOwnableUpgradeable,
    PausableUpgradeable
{
    using Chainlink for Chainlink.Request;

    uint256 public fee;
    
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

    enum DexStatus {
        UNISWAP_V2,
        UNISWAP_V3
    }

    address public SHIB = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public constant PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    address public constant FLOKI = 0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E;
    address public constant MEME = 0xb131f4A55907B10d1F0A50d8ab8FA09EC342cd74;
    address public constant BabyDoge = 0xAC57De9C1A09FeC648E93EB98875B212DB0d460B;
    address public constant BONE = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
    address public constant HarryPotterObamaSonic10Inu = 0x72e4f9F808C49A2a61dE9C5896298920Dc4EEEa9;
    address public constant ELON = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
    address public constant WSM = 0xB62E45c3Df611dcE236A6Ddc7A493d79F9DFadEf;
    address public constant LEASH = 0x27C70Cd1946795B66be9d954418546998b546634;

    address[] public assetList = [
        SHIB,
        PEPE,
        FLOKI,
        MEME,
        BabyDoge,
        BONE,
        HarryPotterObamaSonic10Inu,
        ELON,
        WSM,
        LEASH
    ];
    
    string baseUrl = "https://app.nexlabs.io/api/allFundingRates";
    string urlParams = "?multiplyFunc=18&timesNegFund=true&arrays=true";

    bytes32 public externalJobId;
    uint256 public oraclePayment;

    uint public lastUpdateTime;
    address[] public oracleList;
    address[] public currentList;

    mapping(address => uint) public tokenMarketShare;
    mapping(address => uint) public tokenSwapVersion;

    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    ISwapRouter public constant swapRouterV3 =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory public constant factoryV3 =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    
    IUniswapV2Router02 public constant swapRouterV2 =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant factoryV2 =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IWETH public weth = IWETH(WETH9);
    IQuoter public quoter = IQuoter(QUOTER);

    event FeeReceiverSet(address indexed feeReceiver);
    event FeeRateSet(uint256 indexed feeRatePerDayScaled);
    event MethodologistSet(address indexed methodologist);
    event MethodologySet(string methodology);
    event MinterSet(address indexed minter);
    event SupplyCeilingSet(uint256 supplyCeiling);
    event MintFeeToReceiver(address feeReceiver, uint256 timestamp, uint256 totalSupply, uint256 amount);
    event ToggledRestricted(address indexed account, bool isRestricted);

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
        uint256 _supplyCeiling,
        address _chainlinkToken, 
        address _oracleAddress, 
        bytes32 _externalJobId
    ) external initializer {
        require(_feeReceiver != address(0));

        __Ownable_init();
        __Pausable_init();
        __ERC20_init(tokenName, tokenSymbol);
        __Context_init();

        feeRatePerDayScaled = _feeRatePerDayScaled;
        feeReceiver = _feeReceiver;
        supplyCeiling = _supplyCeiling;
        feeTimestamp = block.timestamp;
        //set oracle data
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_oracleAddress);
        externalJobId = _externalJobId;
        // externalJobId = "81027ac9198848d79a8d14235bf30e16";
        oraclePayment = ((1 * LINK_DIVISIBILITY) / 10); // n * 10**18
    }

   /**
    * @dev The contract's fallback function that does not allow direct payments to the contract.
    * @notice Prevents users from sending ether directly to the contract by reverting the transaction.
    */
    receive() external payable {
        // revert DoNotSendFundsDirectlyToTheContract();
    }

//     function concatenation(string memory a, string memory b) public pure returns (string memory) {
//         return string(bytes.concat(bytes(a), bytes(b)));
//     }

//     function requestFundingRate(
//     )
//         public
//         returns(bytes32)
//     {
        
//         string memory url = concatenation(baseUrl, urlParams);
//         Chainlink.Request memory req = buildChainlinkRequest(externalJobId, address(this), this.fulfillFundingRate.selector);
//         req.add("get", url);
//         req.add("path1", "results,tokens");
//         req.add("path2", "results,marketShares");
//         req.add("path3", "results,swapVersions");
//         // sendOperatorRequest(req, oraclePayment);
//         return sendChainlinkRequestTo(chainlinkOracleAddress(), req, oraclePayment);
//     }

//   function fulfillFundingRate(bytes32 requestId, address[] memory _tokens, uint256[] memory _marketShares, uint256[] memory _swapVersions)
//     public
//     recordChainlinkFulfillment(requestId)
//   {
    
//     oracleList = _tokens;
//     address[] memory tokens0 = _tokens;
//     uint[] memory marketShares0 = _marketShares;
//     uint[] memory swapVersions0 = _swapVersions;

//     // //save mappings
//     for(uint i =0; i < tokens0.length; i++){
//         tokenMarketShare[tokens0[i]] = marketShares0[i];
//         tokenSwapVersion[tokens0[i]] = swapVersions0[i];
//     }
//     lastUpdateTime = block.timestamp;
//   }

    /// @notice External mint function
    /// @dev Mint function can only be called externally by the controller
    /// @param to address
    /// @param amount uint256
    function _mintTo(address to, uint256 amount) internal whenNotPaused {
        require(totalSupply() + amount <= supplyCeiling, "will exceed supply ceiling");
        require(!isRestricted[to], "to is restricted");
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        _mintToFeeReceiver();
        _mint(to, amount);
    }

    
    /// @notice External mint function
    /// @dev Mint function can only be called externally by the controller
    /// @param to address
    /// @param amount uint256
    function mint(address to, uint256 amount) public whenNotPaused onlyMinter {
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
    function _burnTo(address from, uint256 amount) internal whenNotPaused {
        require(!isRestricted[from], "from is restricted");
        require(!isRestricted[msg.sender], "msg.sender is restricted");
        _mintToFeeReceiver();
        _burn(from, amount);
    }


    /// @notice External burn function
    /// @dev burn function can only be called externally by the controller
    /// @param from address
    /// @param amount uint256
    function burn(address from, uint256 amount) public whenNotPaused onlyMinter {
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
    function mintToFeeReceiver() external onlyOwner {
        _mintToFeeReceiver();
    }

    
    /// @notice Only owner function for setting the methodologist
    /// @param _methodologist address
    function setMethodologist(address _methodologist) external onlyOwner {
        require(_methodologist != address(0));
        methodologist = _methodologist;
        emit MethodologistSet(_methodologist);
    }

    /// @notice Callable only by the methodoligst to store on chain data about the underlying weight of the token
    /// @param _methodology string
    function setMethodology(string memory _methodology) external onlyMethodologist {
        methodology = _methodology;
        emit MethodologySet(_methodology);
    }

    /// @notice Ownable function to set the fee rate
    /// @dev Given the annual fee rate this function sets and calculates the rate per second
    /// @param _feeRatePerDayScaled uint256
    function setFeeRate(uint256 _feeRatePerDayScaled) external onlyOwner {
        _mintToFeeReceiver();
        feeRatePerDayScaled = _feeRatePerDayScaled;
        emit FeeRateSet(_feeRatePerDayScaled);
    }

    /// @notice Ownable function to set the receiver
    /// @param _feeReceiver address
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0));
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(_feeReceiver);
    }

    /// @notice Ownable function to set the contract that controls minting
    /// @param _minter address
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
        emit MinterSet(_minter);
    }

    /// @notice Ownable function to set the limit at which the total supply cannot exceed
    /// @param _supplyCeiling uint256
    function setSupplyCeiling(uint256 _supplyCeiling) external onlyOwner {
        supplyCeiling = _supplyCeiling;
        emit SupplyCeilingSet(_supplyCeiling);
    }

    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    
    /// @notice Compliance feature to blacklist bad actors
    /// @dev Negates current restriction state
    /// @param who address
    function toggleRestriction(address who) external onlyOwner {
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

    function approveSwapToken(address _token, address _to, uint _amount) public onlyMinter {
        IERC20(_token).approve(_to, _amount);
    }

    function _swapSingle(address tokenIn, address tokenOut, uint amountIn) internal returns(uint){
        (uint amountOut, DexStatus status) = getAmountOut(tokenIn, tokenOut, amountIn);
        // uint amountOut = 1;
        // DexStatus status = DexStatus.UNISWAP_V3;
        if(amountOut > 0){
            if(status == DexStatus.UNISWAP_V3){
                IERC20(tokenIn).approve(address(swapRouterV3), amountIn);
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
                uint finalAmountOut = swapRouterV3.exactInputSingle(params);
                return finalAmountOut;
            } else{
                address[] memory path = new address[](2);
                path[0] = tokenIn;
                path[1] = tokenOut;

                IERC20(tokenIn).approve(address(swapRouterV2), amountIn);
                swapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn, //amountIn
                    0, //amountOutMin
                    path, //path
                    address(this), //to
                    block.timestamp //deadline
                );
                return amountOut;
            }
        }
    }


    function issuanceIndexTokens(address tokenIn, uint amountIn) public {
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        uint firstPortfolioValue = getPortfolioBalance();
        uint wethAmount = _swapSingle(tokenIn, WETH9, amountIn);
        //swap
        for(uint i = 0; i < 10; i++) {
        _swapSingle(WETH9, assetList[i], wethAmount/10);
        }
       //mint index tokens
       uint amountToMint;
       if(totalSupply() > 0){
        amountToMint = (totalSupply()*wethAmount)/firstPortfolioValue;
       }else{
        amountToMint = wethAmount;
       }

        _mintTo(msg.sender, amountToMint);
    }

    function issuanceIndexTokensWithEth() public payable {
        weth.deposit{value: msg.value}();
        uint firstPortfolioValue = getPortfolioBalance();
        uint wethAmount = msg.value;
        //swap
        for(uint i = 0; i < 10; i++) {
        _swapSingle(WETH9, assetList[i], wethAmount/10);
        // _swapSingle(WETH9, SHIB, wethAmount/10);
        }
       //mint index tokens
       uint amountToMint;
       if(totalSupply() > 0){
        amountToMint = (totalSupply()*wethAmount)/firstPortfolioValue;
       }else{
        amountToMint = wethAmount;
       }

        _mintTo(msg.sender, amountToMint);
    }


    function redemption(address tokenIn, uint amountIn) public {
        // uint firstPortfolioValue = getPortfolioBalance();
        // uint burnPercent = amountIn*1e18/totalSupply();
        uint burnPercent = 1e18;

        _burnTo(msg.sender, amountIn);

       
        //swap
        for(uint i = 0; i < 10; i++) {
        _swapSingle(assetList[i], WETH9, (burnPercent*IERC20(assetList[i]).balanceOf(address(this)))/1e18);
        // _swapSingle(SHIB, WETH9, (burnPercent*IERC20(assetList[i]).balanceOf(address(this)))/1e18/10);
        }
        
        weth.transfer(msg.sender, weth.balanceOf(address(this)));

    }

    function getPool() public returns(address, address) {
        // return factoryV3.getPool(WETH9, SHIB, 3000);
        address v3pool = factoryV3.getPool(WETH9, SHIB, 3000);
       
        address v2pool = factoryV2.getPair(WETH9, SHIB);
        
        return (v3pool, v2pool);
    }

    function getAmounts() public returns(uint, uint) {
        // return factoryV3.getPool(WETH9, SHIB, 3000);
        
        // uint v3AmountOut = quoter.quoteExactInputSingle(WETH9, SHIB, 3000, 1e18, 0);
        uint v3AmountOut;

        try quoter.quoteExactInputSingle(WETH9, LEASH, 3000, 1e18, 0) returns (uint _amount){
            v3AmountOut = _amount;
        } catch {
            v3AmountOut = 0;
        }
        // uint v3AmountOut = 0;

        address[] memory path = new address[](2);
        path[0] = WETH9;
        path[1] = LEASH;
        
        
        uint v2amountOut;
        try swapRouterV2.getAmountsOut(1e18, path) returns (uint[] memory _amounts){
            v2amountOut = _amounts[1];
        } catch {
            v2amountOut = 0;
        }
        return (v3AmountOut, v2amountOut);

    }


    function getAmountOut(address tokenIn, address tokenOut, uint amountIn) public returns(uint finalAmountOut, DexStatus dexStatus) {
        uint v3AmountOut;
        try quoter.quoteExactInputSingle(tokenIn, tokenOut, 3000, amountIn, 0) returns (uint _amount){
            v3AmountOut = _amount;
        } catch {
            v3AmountOut = 0;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        
        uint v2amountOut;
        try swapRouterV2.getAmountsOut(amountIn, path) returns (uint[] memory _amounts){
            v2amountOut = _amounts[1];
        } catch {
            v2amountOut = 0;
        }
        
        finalAmountOut = v3AmountOut > v2amountOut ? v3AmountOut : v2amountOut;
        dexStatus = v3AmountOut > v2amountOut ? DexStatus.UNISWAP_V3 : DexStatus.UNISWAP_V2;
        
    }


    function getPortfolioBalance() public returns(uint){
        uint totalValue;
        for(uint i = 0; i < 10; i++) {
            (uint value, DexStatus status) = getAmountOut(assetList[i], WETH9, IERC20(assetList[i]).balanceOf(address(this)));
            totalValue += value;
        }
        return totalValue;
    }


    function swapGas() public payable {
        weth.deposit{value: msg.value}();
        weth.approve(address(swapRouterV3), msg.value);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: SHIB,
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: msg.value,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        uint finalAmountOut = swapRouterV3.exactInputSingle(params);
    }


    function swapGas1() public payable {
        uint amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);
        amountsOutt = estimateAmountOut(WETH9, SHIB, uint128(msg.value), 1);


        weth.deposit{value: msg.value}();
        weth.approve(address(swapRouterV3), msg.value);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: SHIB,
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: msg.value/10,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        uint finalAmountOut = swapRouterV3.exactInputSingle(params);
        // uint finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
        finalAmountOut = swapRouterV3.exactInputSingle(params);
    }



    function estimateAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint32 secondsAgo
    ) public view returns (uint amountOut) {
        // require(tokenIn == token0 || tokenIn == token1, "invalid token");

        // address tokenOut = tokenIn == token0 ? token1 : token0;
        address _pool = factoryV3.getPool(
            tokenIn,
            tokenOut,
            3000
        );

        (int24 tick, ) = OracleLibrary.consult(_pool, secondsAgo);
        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            tokenIn,
            tokenOut
        );
    }
    
}