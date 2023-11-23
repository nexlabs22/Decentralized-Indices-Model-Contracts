// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../token/IndexToken.sol";
import "../proposable/ProposableOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
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
import "../token/RequestNFT.sol";

/// @title Index Token
/// @author NEX Labs Protocol
/// @notice The main token contract for Index Token (NEX Labs Protocol)
/// @dev This contract uses an upgradeable pattern
contract IndexFactory is
    ChainlinkClient,
    ContextUpgradeable,
    ProposableOwnableUpgradeable,
    PausableUpgradeable
{
    using Chainlink for Chainlink.Request;

    IndexToken public indexToken;
    RequestNFT public nft;

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
    // address[] public oracleList;
    // address[] public currentList;

    uint public totalOracleList;
    uint public totalCurrentList;

    mapping(uint => address) public oracleList;
    mapping(uint => address) public currentList;

    mapping(address => uint) public tokenOracleListIndex;
    mapping(address => uint) public tokenCurrentListIndex;

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
        address payable _token,
        address _nft,
        address _chainlinkToken, 
        address _oracleAddress, 
        bytes32 _externalJobId
    ) external initializer {

        __Ownable_init();
        __Pausable_init();
        indexToken = IndexToken(_token);
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

    function concatenation(string memory a, string memory b) public pure returns (string memory) {
        return string(bytes.concat(bytes(a), bytes(b)));
    }
    
    function requestFundingRate(
    )
        public
        returns(bytes32)
    {
        
        string memory url = concatenation(baseUrl, urlParams);
        Chainlink.Request memory req = buildChainlinkRequest(externalJobId, address(this), this.fulfillFundingRate.selector);
        req.add("get", url);
        req.add("path1", "results,tokens");
        req.add("path2", "results,marketShares");
        req.add("path3", "results,swapVersions");
        // sendOperatorRequest(req, oraclePayment);
        return sendChainlinkRequestTo(chainlinkOracleAddress(), req, oraclePayment);
    }

  function fulfillFundingRate(bytes32 requestId, address[] memory _tokens, uint256[] memory _marketShares, uint256[] memory _swapVersions)
    public
    recordChainlinkFulfillment(requestId)
  {
    
    // oracleList = _tokens;
    // if(currentList.length == 0){
    //     currentList = _tokens;
    // }
    address[] memory tokens0 = _tokens;
    uint[] memory marketShares0 = _marketShares;
    uint[] memory swapVersions0 = _swapVersions;

    // //save mappings
    for(uint i =0; i < tokens0.length; i++){
        oracleList[i] = tokens0[i];
        tokenOracleListIndex[tokens0[i]] = i;
        tokenMarketShare[tokens0[i]] = marketShares0[i];
        tokenSwapVersion[tokens0[i]] = swapVersions0[i];
        if(totalCurrentList == 0){
            currentList[i] = tokens0[i];
            tokenCurrentListIndex[tokens0[i]] = i;
        }
    }
    totalOracleList = tokens0.length;
    if(totalCurrentList == 0){
        totalCurrentList  = tokens0.length;
    }
    lastUpdateTime = block.timestamp;
    }

    

    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    
    

    function _swapSingle(address tokenIn, address tokenOut, uint amountIn, address _recipient, uint _swapVersion) internal returns(uint){
        uint amountOut = getAmountOut(tokenIn, tokenOut, amountIn, _swapVersion);
        // uint amountOut = 1;
        // DexStatus status = DexStatus.UNISWAP_V3;
        if(amountOut > 0){
            if(_swapVersion == 3){
                IERC20(tokenIn).approve(address(swapRouterV3), amountIn);
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    // pool fee 0.3%
                    fee: 3000,
                    recipient: _recipient,
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
                    _recipient, //to
                    block.timestamp //deadline
                );
                return amountOut;
            }
        }
    }


    function issuanceIndexTokens(address tokenIn, uint amountIn) public {
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        uint firstPortfolioValue = getPortfolioBalance();
        uint wethAmount = _swapSingle(tokenIn, WETH9, amountIn, address(this), tokenSwapVersion[tokenIn]);
        //swap
        for(uint i = 0; i < totalCurrentList; i++) {
        _swapSingle(WETH9, currentList[i], wethAmount*tokenMarketShare[currentList[i]]/100e18, address(this), tokenSwapVersion[currentList[i]]);
        }
       //mint index tokens
       uint amountToMint;
       if(indexToken.totalSupply() > 0){
        amountToMint = (indexToken.totalSupply()*wethAmount)/firstPortfolioValue;
       }else{
        amountToMint = wethAmount;
       }

        indexToken.mint(msg.sender, amountToMint);
    }

    function issuanceIndexTokensWithEth() public payable {
        weth.deposit{value: msg.value}();
        uint firstPortfolioValue = getPortfolioBalance();
        uint wethAmount = msg.value;
        //swap
        for(uint i = 0; i < totalCurrentList; i++) {
        // _swapSingle(WETH9, currentList[i], wethAmount*tokenMarketShare[currentList[i]]/100e18, address(this), tokenSwapVersion[currentList[i]]);
        _swapSingle(WETH9, currentList[i], wethAmount*tokenMarketShare[currentList[i]]/100e18, address(this), tokenSwapVersion[currentList[i]]);
        // _swapSingle(WETH9, SHIB, wethAmount/10);
        }
       //mint index tokens
       uint amountToMint;
       if(indexToken.totalSupply() > 0){
        amountToMint = (indexToken.totalSupply()*wethAmount)/firstPortfolioValue;
       }else{
        amountToMint = wethAmount;
       }

        indexToken.mint(msg.sender, amountToMint);
    }


    function redemption(uint amountIn) public {
        uint firstPortfolioValue = getPortfolioBalance();
        uint burnPercent = amountIn*1e18/indexToken.totalSupply();
        // uint burnPercent = 1e18;

        indexToken.burn(msg.sender, amountIn);

       
        //swap
        for(uint i = 0; i < totalCurrentList; i++) {
        uint swapAmount = (burnPercent*IERC20(currentList[i]).balanceOf(address(this)))/1e18;
        // indexToken.approveSwapToken(currentList[i], address(this), swapAmount);
        // indexToken.transferFrom(address(indexToken), address(this), swapAmount);
        _swapSingle(currentList[i], WETH9, swapAmount, address(this), tokenSwapVersion[currentList[i]]);
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


    function getAmountOut(address tokenIn, address tokenOut, uint amountIn, uint _swapVersion) public returns(uint finalAmountOut) {
        uint finalAmountOut;
        if(amountIn > 0){
        if(_swapVersion == 3){
        //    finalAmountOut = quoter.quoteExactInputSingle(tokenIn, tokenOut, 3000, amountIn, 0);
           finalAmountOut = estimateAmountOut(tokenIn, tokenOut, uint128(amountIn), 1);
        }else {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            uint[] memory v2amountOut = swapRouterV2.getAmountsOut(amountIn, path);
            finalAmountOut = v2amountOut[1];
        }
        }
        return finalAmountOut;
    }


    function getPortfolioBalance() public returns(uint){
        uint totalValue;
        for(uint i = 0; i < totalCurrentList; i++) {
            uint value = getAmountOut(currentList[i], WETH9, IERC20(currentList[i]).balanceOf(address(this)), tokenSwapVersion[currentList[i]]);
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

    function sswap() public payable {
        weth.deposit{value: msg.value}();
        _swapSingle(WETH9, SHIB, msg.value, address(this), tokenSwapVersion[SHIB]);
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

    function getNewTokens() public returns (address[] memory){
        address[] memory newTokens;
        for(uint i; i < totalOracleList; i++) {
        tokenOracleListIndex[tokens0[i]] = i;
            if(tokenCurrentListIndex[oracleList[i]] > totalCurrentList ||(tokenCurrentListIndex[oracleList[i]] == 0 && tokenCurrentListIndex[oracleList[i]] != currentList[0])){
                newTokens.push(tokens0[i]);
            }
        }
        return newTokens;
    }


    function getOldTokens() public returns (address[] memory){
        address[] memory oldTokens;
        for(uint i; i < totalCurrentList; i++) {
        tokenCurrentListIndex[tokens0[i]] = i;
            if(tokenOracleListIndex[oracleList[i]] > totalOracleList ||(tokenOracleListIndex[oracleList[i]] == 0 && tokenOracleListIndex[oracleList[i]] != oracleList[0])){
                newTokens.push(tokens0[i]);
            }
        }
        return oldTokens;
    }

    
}