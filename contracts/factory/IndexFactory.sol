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
import "../libraries/SwapHelpers.sol";
import "./IndexFactoryStorage.sol";

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
    
    IndexFactoryStorage public factoryStorage;

    event Issuanced(
        address indexed user,
        address indexed inputToken,
        uint inputAmount,
        uint outputAmount,
        uint time
    );

    event Redemption(
        address indexed user,
        address indexed outputToken,
        uint inputAmount,
        uint outputAmount,
        uint time
    );

    

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _factoryStorage The address of the Uniswap V2 factory.
     */
    function initialize(
        address payable _factoryStorage
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        factoryStorage = IndexFactoryStorage(_factoryStorage);
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
     * @dev The contract's fallback function that does not allow direct payments to the contract.
     * @notice Prevents users from sending ether directly to the contract by reverting the transaction.
     */
    receive() external payable {
        // revert DoNotSendFundsDirectlyToTheContract();
    }

    

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Internal function to swap tokens.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input token.
     * @param _recipient The address of the recipient.
     * @param _swapFee The swap version (2 for Uniswap V2, 3 for Uniswap V3).
     * @return outputAmount The amount of output token.
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address _recipient,
        uint24 _swapFee
    ) internal returns (uint outputAmount) {
        ISwapRouter swapRouterV3 = factoryStorage.swapRouterV3();
        IUniswapV2Router02 swapRouterV2 = factoryStorage.swapRouterV2();
        outputAmount = SwapHelpers.swap(
            swapRouterV3,
            swapRouterV2,
            _swapFee,
            tokenIn,
            tokenOut,
            amountIn,
            _recipient
        );
    }

    function _mintIndexTokensForIssuance(
        uint _wethAmount,
        uint _firstPortfolioValue
    ) internal returns(uint amountToMint) {
        //mint index tokens
        IndexToken indexToken = factoryStorage.indexToken();
        if (indexToken.totalSupply() > 0) {
            amountToMint =
                (indexToken.totalSupply() * _wethAmount) /
                _firstPortfolioValue;
        } else {
            uint price = factoryStorage.priceInWei();
            amountToMint = (_wethAmount * price) / 1e16;
        }
        indexToken.mint(msg.sender, amountToMint);
    }

    function _issuance(
        address _tokenIn,
        uint _amountIn,
        uint _totalCurrentList,
        Vault _vault,
        uint _wethAmount,
        uint _firstPortfolioValue
    ) internal {
        IWETH weth = factoryStorage.weth();
        //swap
        for (uint i = 0; i < _totalCurrentList; i++) {
            address tokenAddress = factoryStorage.currentList(i);
            uint marketShare = factoryStorage.tokenCurrentMarketShare(tokenAddress);
            uint24 swapFee = factoryStorage.tokenSwapFee(tokenAddress);
            if (tokenAddress != address(weth)) {
                swap(
                    address(weth),
                    tokenAddress,
                    (_wethAmount * marketShare) /
                        100e18,
                    address(_vault),
                    swapFee
                );
            }else{
                weth.transfer(address(_vault), (_wethAmount * marketShare) /
                        100e18);
            }
        }
        //mint index tokens
        uint amountToMint = _mintIndexTokensForIssuance(_wethAmount, _firstPortfolioValue);
        emit Issuanced(
            msg.sender,
            _tokenIn,
            _amountIn,
            amountToMint,
            block.timestamp
        );
    }

    /**
     * @dev Issues index tokens by swapping the input token.
     * @param _tokenIn The address of the input token.
     * @param _amountIn The amount of input token.
     * @param _tokenInSwapFee The swap version of the input token.
     */
    function issuanceIndexTokens(
        address _tokenIn,
        uint _amountIn,
        uint24 _tokenInSwapFee
    ) public {
        IWETH weth = factoryStorage.weth();
        Vault vault = factoryStorage.vault();
        uint totalCurrentList = factoryStorage.totalCurrentList();
        uint feeRate = factoryStorage.feeRate();
        uint feeAmount = (_amountIn * feeRate) / 10000;

        uint firstPortfolioValue = factoryStorage.getPortfolioBalance();

        IERC20(_tokenIn).transferFrom(
            msg.sender,
            address(this),
            _amountIn + feeAmount
        );
        uint wethAmountBeforFee = swap(
            _tokenIn,
            address(weth),
            _amountIn + feeAmount,
            address(this),
            _tokenInSwapFee
        );
        address feeReceiver = factoryStorage.feeReceiver();
        uint feeWethAmount = (wethAmountBeforFee * feeRate) / 10000;
        uint wethAmount = wethAmountBeforFee - feeWethAmount;

        
        //giving fee to the fee receiver
        weth.transfer(address(feeReceiver), feeWethAmount);
        _issuance(
            _tokenIn,
            _amountIn,
            totalCurrentList,
            vault,
            wethAmount,
            firstPortfolioValue
        );
    }

    /**
     * @dev Issues index tokens with ETH.
     * @param _inputAmount The amount of ETH input.
     */
    function issuanceIndexTokensWithEth(uint _inputAmount) public payable {
        Vault vault = factoryStorage.vault();
        IWETH weth = factoryStorage.weth();
        address feeReceiver = factoryStorage.feeReceiver();
        uint feeRate = factoryStorage.feeRate();
        uint feeAmount = (_inputAmount * feeRate) / 10000;
        uint finalAmount = _inputAmount + feeAmount;
        require(msg.value >= finalAmount, "lower than required amount");
        weth.deposit{value: finalAmount}();
        weth.transfer(address(feeReceiver), feeAmount);
        uint totalCurrentList = factoryStorage.totalCurrentList();
        uint firstPortfolioValue = factoryStorage.getPortfolioBalance();
        _issuance(
            address(weth),
            _inputAmount,
            totalCurrentList,
            vault,
            _inputAmount,
            firstPortfolioValue
        );
    }

    function _swapToOutputToken(
        uint _amountIn,
        uint _outputAmount,
        address _tokenOut,
        uint24 _tokenOutSwapFee,
        uint feeRate,
        address feeReceiver
    ) internal returns(uint realOut) {
        IWETH weth = factoryStorage.weth();
        uint ownerFee = (_outputAmount * feeRate) / 10000;
        if (_tokenOut == address(weth)) {
            weth.withdraw(_outputAmount - ownerFee);
            weth.transfer(address(feeReceiver), ownerFee);
            (bool _userSuccess, ) = payable(msg.sender).call{
                value: _outputAmount - ownerFee
            }("");
            require(_userSuccess, "transfer eth fee to the user failed");
            emit Redemption(
                msg.sender,
                _tokenOut,
                _amountIn,
                _outputAmount - ownerFee,
                block.timestamp
            );
            return _outputAmount - ownerFee;
        } else {
            weth.transfer(address(feeReceiver), ownerFee);
            uint realOut = swap(
                address(weth),
                _tokenOut,
                _outputAmount - ownerFee,
                msg.sender,
                _tokenOutSwapFee
            );
            emit Redemption(
                msg.sender,
                _tokenOut,
                _amountIn,
                realOut,
                block.timestamp
            );
            return realOut;
        }
    }

    function _redemptionSwaps(
        uint _burnPercent,
        uint _totalCurrentList,
        Vault _vault
    ) internal returns(uint outputAmount) {
        IWETH weth = factoryStorage.weth();
        for (uint i = 0; i < _totalCurrentList; i++) {
            address tokenAddress = factoryStorage.currentList(i);
            uint24 swapFee = factoryStorage.tokenSwapFee(tokenAddress);
            uint swapAmount = (_burnPercent * IERC20(tokenAddress).balanceOf(address(_vault))) / 1e18;
            if (tokenAddress != address(weth)) {
                _vault.withdrawFunds(
                    tokenAddress,
                    address(this),
                    swapAmount
                );
                uint swapAmountOut = swap(
                    tokenAddress,
                    address(weth),
                    swapAmount,
                    address(this),
                    swapFee
                );
                outputAmount += swapAmountOut;
            } else {
                _vault.withdrawFunds(
                    address(weth),
                    address(this),
                    swapAmount
                );
                outputAmount += swapAmount;
            }
        }
    }

    function _redemption(
        uint _totalCurrentList,
        Vault _vault,
        uint _burnPercent,
        address _tokenOut,
        uint24 _tokenOutSwapFee,
        uint feeRate,
        address feeReceiver
    ) internal returns(uint realOut) {
        IndexToken indexToken = factoryStorage.indexToken();
        uint outputAmount;
        //swap
        outputAmount = _redemptionSwaps(_burnPercent, _totalCurrentList, _vault);
        realOut = _swapToOutputToken(
            _burnPercent,
            outputAmount,
            _tokenOut,
            _tokenOutSwapFee,
            feeRate,
            feeReceiver
        );
    }

    /**
     * @dev Redeems index tokens for the specified output token.
     * @param amountIn The amount of index tokens to redeem.
     * @param _tokenOut The address of the output token.
     * @param _tokenOutSwapFee The swap version of the output token.
     * @return The amount of output token.
     */
    function redemption(
        uint amountIn,
        address _tokenOut,
        uint24 _tokenOutSwapFee
    ) public returns (uint) {
        Vault vault = factoryStorage.vault();
        uint totalCurrentList = factoryStorage.totalCurrentList();
        uint feeRate = factoryStorage.feeRate();
        address feeReceiver = factoryStorage.feeReceiver();
        IndexToken indexToken = factoryStorage.indexToken();
        uint burnPercent = (amountIn * 1e18) / indexToken.totalSupply();
        
        indexToken.burn(msg.sender, amountIn);

        uint realOut = _redemption(
            factoryStorage.totalCurrentList(),
            vault,
            burnPercent,
            _tokenOut,
            _tokenOutSwapFee,
            feeRate,
            feeReceiver
        );

        return realOut;
        
    }
}
