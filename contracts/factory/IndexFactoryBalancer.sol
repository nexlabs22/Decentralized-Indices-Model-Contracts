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
contract IndexFactoryBalancer is
    ChainlinkClient,
    ContextUpgradeable,
    ProposableOwnableUpgradeable,
    PausableUpgradeable
{
    
    IndexFactoryStorage public factoryStorage;

    

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _factoryStorage The address of the Uniswap V2 factory.
     */
    function initialize(
        address payable _factoryStorage
    ) external initializer {
        require(_factoryStorage != address(0), "Invalid factory storage address");
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
        revert("DoNotSendFundsDirectlyToTheContract");
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed");
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
     * @param _swapFee The swap fee.
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
        // Ensure the transfer is successful
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
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

    /**
     * @dev Reindexes and reweights the portfolio.
     */
    function reIndexAndReweight() public onlyOwner {
        IWETH weth = factoryStorage.weth();
        Vault vault = factoryStorage.vault();
        uint totalCurrentList = factoryStorage.totalCurrentList();
        uint totalOracleList = factoryStorage.totalOracleList();
        for (uint i; i < totalCurrentList; i++) {
            address tokenAddress = factoryStorage.currentList(i);
            uint24 tokenSwapFee = factoryStorage.tokenSwapFee(tokenAddress);
            if (tokenAddress != address(weth)) {
                bool success = vault.withdrawFunds(
                    tokenAddress,
                    address(this),
                    IERC20(tokenAddress).balanceOf(address(vault))
                );
                require(success, "Vault withdrawal failed");
                uint outputAmount = swap(
                        tokenAddress,
                        address(weth),
                        IERC20(tokenAddress).balanceOf(address(vault)),
                        address(vault),
                        tokenSwapFee
                    );
                require(outputAmount > 0, "Swap failed");
            }
        }
        uint wethBalance = weth.balanceOf(address(this));
        for (uint i; i < totalOracleList; i++) {
            address tokenAddress = factoryStorage.oracleList(i);
            uint24 tokenSwapFee = factoryStorage.tokenSwapFee(tokenAddress);
            uint tokenOracleMarketShare = factoryStorage.tokenOracleMarketShare(tokenAddress);
            if (tokenAddress != address(weth)) {
                bool success = vault.withdrawFunds(
                    address(weth),
                    address(this),
                    wethBalance
                );
                require(success, "Vault withdrawal failed");
                uint outputAmount = swap(
                    address(weth),
                    tokenAddress,
                    (wethBalance * tokenOracleMarketShare) /
                        100e18,
                    address(vault),
                    tokenSwapFee
                );
                require(outputAmount > 0, "Swap failed");
            }
            //update current list
            factoryStorage.updateCurrentList();
        }
    }
}
