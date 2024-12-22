// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../token/IndexToken.sol";
import "../proposable/ProposableOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../chainlink/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceOracle.sol";
import "../vault/Vault.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Index Token
/// @author NEX Labs Protocol
/// @notice The main token contract for Index Token (NEX Labs Protocol)
/// @dev This contract uses an upgradeable pattern
contract IndexFactoryStorage is
    Initializable,
    ChainlinkClient,
    ContextUpgradeable,
    ProposableOwnableUpgradeable,
    PausableUpgradeable
{
    using Chainlink for Chainlink.Request;

    IndexToken public indexToken;

    uint256 public fee;
    uint8 public feeRate; // 10/10000 = 0.1%
    uint256 public latestFeeUpdate;
    // Address that can claim fees accrued.
    address public feeReceiver;



    string baseUrl;
    string urlParams;

    address public priceOracle;
    bytes32 public externalJobId;
    uint256 public oraclePayment;
    AggregatorV3Interface public toUsdPriceFeed;
    uint public lastUpdateTime;
    
    uint public totalOracleList;
    uint public totalCurrentList;

    mapping(uint => address) public oracleList;
    mapping(uint => address) public currentList;

    mapping(address => uint) public tokenOracleListIndex;
    mapping(address => uint) public tokenCurrentListIndex;

    mapping(address => uint) public tokenCurrentMarketShare;
    mapping(address => uint) public tokenOracleMarketShare;
    mapping(address => uint24) public tokenSwapFee;

    address public factoryAddress;
    address public factoryBalancerAddress;
    ISwapRouter public swapRouterV3;
    IUniswapV3Factory public factoryV3;
    IUniswapV2Router02 public swapRouterV2;
    IUniswapV2Factory public factoryV2;
    IWETH public weth;
    IQuoter public quoter;
    Vault public vault;


    event FeeReceiverSet(address indexed feeReceiver);
    

    

    /**
     * @dev Throws if the caller is not a factory contract.
     */
    modifier onlyFactory() {
        require(msg.sender == factoryAddress || msg.sender == factoryBalancerAddress, "Caller is not a factory contract");
        _;
    }

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _token The address of the IndexToken contract.
     * @param _chainlinkToken The address of the Chainlink token.
     * @param _oracleAddress The address of the Chainlink oracle.
     * @param _externalJobId The external job ID for Chainlink requests.
     * @param _toUsdPriceFeed The address of the USD price feed.
     * @param _weth The address of the WETH token.
     * @param _quoter The address of the Uniswap V3 quoter.
     * @param _swapRouterV3 The address of the Uniswap V3 swap router.
     * @param _factoryV3 The address of the Uniswap V3 factory.
     * @param _swapRouterV2 The address of the Uniswap V2 swap router.
     * @param _factoryV2 The address of the Uniswap V2 factory.
     */
    function initialize(
        address payable _token,
        address _chainlinkToken,
        address _oracleAddress,
        bytes32 _externalJobId,
        address _toUsdPriceFeed,
        //addresses
        address _weth,
        address _quoter,
        address _swapRouterV3,
        address _factoryV3,
        address _swapRouterV2,
        address _factoryV2
    ) external initializer {

        __Ownable_init();
        __Pausable_init();
        indexToken = IndexToken(_token);
        //set oracle data
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_oracleAddress);
        externalJobId = _externalJobId;
        oraclePayment = ((1 * LINK_DIVISIBILITY) / 10); // n * 10**18
        toUsdPriceFeed = AggregatorV3Interface(_toUsdPriceFeed);
        //set addresses
        weth = IWETH(_weth);
        quoter = IQuoter(_quoter);
        swapRouterV3 = ISwapRouter(_swapRouterV3);
        factoryV3 = IUniswapV3Factory(_factoryV3);
        swapRouterV2 = IUniswapV2Router02(_swapRouterV2);
        factoryV2 = IUniswapV2Factory(_factoryV2);

        feeRate = 10;
        latestFeeUpdate = block.timestamp;

        baseUrl = "https://app.nexlabs.io/api/allFundingRates";
        urlParams = "?multiplyFunc=18&timesNegFund=true&arrays=true";
        // s_requestCount = 1;
        feeReceiver = msg.sender;
    }

    function setFactory(address _factoryAddress) public onlyOwner {
        factoryAddress = _factoryAddress;
    }

    function setFactoryBalancer(address _factoryBalancerAddress) public onlyOwner {
        factoryBalancerAddress = _factoryBalancerAddress;
    }
    /**
     * @dev Sets the fee receiver address.
     * @param _feeReceiver The address of the fee receiver.
     */
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(_feeReceiver);
    }

     /**
     * @dev Sets the vault address.
     * @param _vaultAddress The address of the vault.
     */
    function setVault(address _vaultAddress) public onlyOwner {
        vault = Vault(_vaultAddress);
    }

    /**
     * @dev Sets the price feed address of the native coin to USD from the Chainlink oracle.
     * @param _toUsdPricefeed The address of native coin to USD price feed.
     */
    function setPriceFeed(address _toUsdPricefeed) external onlyOwner {
        require(
            _toUsdPricefeed != address(0),
            "ICO: Price feed address cannot be zero address"
        );
        toUsdPriceFeed = AggregatorV3Interface(_toUsdPricefeed);
    }

    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(
            _priceOracle != address(0),
            "Price oracle address cannot be zero address"
        );
        priceOracle = _priceOracle;
    }

    /**
     * @dev Converts an amount to Wei based on the given decimals.
     * @param _amount The amount to convert.
     * @param _amountDecimals The decimals of the amount.
     * @param _chainDecimals The decimals of the chain.
     * @return The amount in Wei.
     */
    function _toWei(
        int256 _amount,
        uint8 _amountDecimals,
        uint8 _chainDecimals
    ) private pure returns (int256) {
        if (_chainDecimals > _amountDecimals)
            return _amount * int256(10 ** (_chainDecimals - _amountDecimals));
        else return _amount * int256(10 ** (_amountDecimals - _chainDecimals));
    }

    /**
     * @dev Returns the price in Wei.
     * @return The price in Wei.
     */
    function priceInWei() public view returns (uint256) {
        (, int price, , , ) = toUsdPriceFeed.latestRoundData();
        uint8 priceFeedDecimals = toUsdPriceFeed.decimals();
        price = _toWei(price, priceFeedDecimals, 18);
        return uint256(price);
    }

    /**
     * @dev Sets the fee rate. The new fee should be between 1 to 100 (0.01% - 1%).
     * @param _newFee The new fee rate.
     */
    //Notice: newFee should be between 1 to 100 (0.01% - 1%)
    function setFeeRate(uint8 _newFee) public onlyOwner {
        uint256 distance = block.timestamp - latestFeeUpdate;
        require(
            distance / 60 / 60 > 12,
            "You should wait at least 12 hours after the latest update"
        );
        require(
            _newFee <= 100 && _newFee >= 1,
            "The newFee should be between 1 and 100 (0.01% - 1%)"
        );
        feeRate = _newFee;
        latestFeeUpdate = block.timestamp;
    }

    

    /**
     * @dev Concatenates two strings.
     * @param a The first string.
     * @param b The second string.
     * @return The concatenated string.
     */
    function concatenation(
        string memory a,
        string memory b
    ) public pure returns (string memory) {
        return string(bytes.concat(bytes(a), bytes(b)));
    }

    /**
     * @dev Sets the base URL and URL parameters.
     * @param _beforeAddress The base URL.
     * @param _afterAddress The URL parameters.
     */
    function setUrl(
        string memory _beforeAddress,
        string memory _afterAddress
    ) public onlyOwner {
        baseUrl = _beforeAddress;
        urlParams = _afterAddress;
    }

    /**
     * @dev Requests asset data from the Chainlink oracle.
     * @return The request ID.
     */
    function requestAssetsData() public returns (bytes32) {
        string memory url = concatenation(baseUrl, urlParams);
        Chainlink.Request memory req = buildChainlinkRequest(
            externalJobId,
            address(this),
            this.fulfillAssetsData.selector
        );
        req.add("get", url);
        req.add("path1", "results,tokens");
        req.add("path2", "results,marketShares");
        req.add("path3", "results,swapFees");
        return
            sendChainlinkRequestTo(
                chainlinkOracleAddress(),
                req,
                oraclePayment
            );
    }

    /**
     * @dev Fulfills the asset data request from the Chainlink oracle.
     * @param requestId The request ID.
     * @param _tokens The list of token addresses.
     * @param _marketShares The list of market shares.
     * @param _swapFees The list of swap versions.
     */
    function fulfillAssetsData(
        bytes32 requestId,
        address[] memory _tokens,
        uint256[] memory _marketShares,
        uint24[] memory _swapFees
    ) public recordChainlinkFulfillment(requestId) {
        
        require(
            _tokens.length == _marketShares.length &&
                _marketShares.length == _swapFees.length,
            "The length of the arrays should be the same"
        );
        address[] memory tokens0 = _tokens;
        uint[] memory marketShares0 = _marketShares;
        uint24[] memory _swapFees = _swapFees;

        // //save mappings
        for (uint i = 0; i < tokens0.length; i++) {
            oracleList[i] = tokens0[i];
            tokenOracleListIndex[tokens0[i]] = i;
            tokenOracleMarketShare[tokens0[i]] = marketShares0[i];
            tokenSwapFee[tokens0[i]] = _swapFees[i];
            if (totalCurrentList == 0) {
                currentList[i] = tokens0[i];
                tokenCurrentMarketShare[tokens0[i]] = marketShares0[i];
                tokenCurrentListIndex[tokens0[i]] = i;
            }
        }
        totalOracleList = tokens0.length;
        if (totalCurrentList == 0) {
            totalCurrentList = tokens0.length;
        }
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Mock function to fill the asset list for testing purposes.
     * @param _tokens The list of token addresses.
     * @param _marketShares The list of market shares.
     * @param _swapFees The list of swap versions.
     */
    function mockFillAssetsList(
        address[] memory _tokens,
        uint256[] memory _marketShares,
        uint24[] memory _swapFees
    ) public onlyOwner {
        address[] memory tokens0 = _tokens;
        uint[] memory marketShares0 = _marketShares;
        uint24[] memory _swapFees = _swapFees;

        // //save mappings
        for (uint i = 0; i < tokens0.length; i++) {
            oracleList[i] = tokens0[i];
            tokenOracleListIndex[tokens0[i]] = i;
            tokenOracleMarketShare[tokens0[i]] = marketShares0[i];
            tokenSwapFee[tokens0[i]] = _swapFees[i];
            if (totalCurrentList == 0) {
                currentList[i] = tokens0[i];
                tokenCurrentMarketShare[tokens0[i]] = marketShares0[i];
                tokenCurrentListIndex[tokens0[i]] = i;
            }
        }
        totalOracleList = tokens0.length;
        if (totalCurrentList == 0) {
            totalCurrentList = tokens0.length;
        }
        lastUpdateTime = block.timestamp;
    }

    
    function updateCurrentList() external onlyFactory {
        totalCurrentList = totalOracleList;
        for(uint i = 0; i < totalOracleList; i++){
            address tokenAddress = oracleList[i];
            currentList[i] = tokenAddress;
            tokenCurrentMarketShare[tokenAddress] = tokenOracleMarketShare[tokenAddress];
        }
    }
    

    /**
     * @dev Gets the amount out for a token swap.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input token.
     * @param _swapFee The swap fee.
     * @return finalAmountOut The amount of output token.
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint24 _swapFee
    ) public view returns (uint finalAmountOut) {
        if (amountIn > 0) {
            if (_swapFee > 0) {
                finalAmountOut = estimateAmountOut(
                    tokenIn,
                    tokenOut,
                    uint128(amountIn),
                    _swapFee
                );
            } else {
                address[] memory path = new address[](2);
                path[0] = tokenIn;
                path[1] = tokenOut;
                uint[] memory v2amountOut = swapRouterV2.getAmountsOut(
                    amountIn,
                    path
                );
                finalAmountOut = v2amountOut[1];
            }
        }
        return finalAmountOut;
    }

    /**
     * @dev Gets the portfolio balance in WETH.
     * @return The portfolio balance in WETH.
     */
    function getPortfolioBalance() public view returns (uint) {
        uint totalValue;
        for (uint i = 0; i < totalCurrentList; i++) {
            if (currentList[i] == address(weth)) {
                totalValue += IERC20(currentList[i]).balanceOf(
                    address(vault)
                );
            } else {
                uint value = getAmountOut(
                    currentList[i],
                    address(weth),
                    IERC20(currentList[i]).balanceOf(address(vault)),
                    tokenSwapFee[currentList[i]]
                );
                totalValue += value;
            }
        }
        return totalValue;
    }

    function getPortfolioBalance2(address token) public view returns (address) {
        uint totalValue;
        // uint value = getAmountOut(
        //             token,
        //             address(weth),
        //             1e18,
        //             3000
        //         );
        // totalValue += value;

        totalValue = IPriceOracle(priceOracle).estimateAmountOut(
            address(factoryV3),
            token,
            address(weth),
            1e18,
            3000
        );
        return priceOracle;
    }

    /**
     * @dev Estimates the amount out for a token swap using Uniswap V3.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input token.
     * @return amountOut The estimated amount of output token.
     */
    function estimateAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 swapFee
    ) public view returns (uint amountOut) {
        amountOut = IPriceOracle(priceOracle).estimateAmountOut(
            address(factoryV3),
            tokenIn,
            tokenOut,
            amountIn,
            swapFee
        );
    }

    
}
