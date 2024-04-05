// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;
pragma solidity 0.8.7;

import "forge-std/Test.sol";
// import "../../contracts/test/MockRouter.sol";
// import "../../contracts/test/LinkToken.sol";
// import "../../contracts/ccip/BasicMessageSender.sol";
// import "../../contracts/ccip/BasicTokenSender.sol";
// import "../../contracts/ccip/BasicMessageReceiver.sol";
// import "../../contracts/test/Token.sol";

import "../../contracts/token/IndexToken.sol";
import "../../contracts/test/MockV3Aggregator.sol";
import "../../contracts/test/MockApiOracle.sol";
import "../../contracts/test/LinkToken.sol";
import "../../contracts/test/UniswapFactoryByteCode.sol";
import "../../contracts/test/UniswapWETHByteCode.sol";
import "../../contracts/test/UniswapRouterByteCode.sol";
import "../../contracts/test/UniswapPositionManagerByteCode.sol";
import "../../contracts/factory/IndexFactory.sol";
import "../../contracts/test/TestSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../../contracts/interfaces/IUniswapV3Pool.sol";


contract ContractDeployer is Test, UniswapFactoryByteCode, UniswapWETHByteCode, UniswapRouterByteCode, UniswapPositionManagerByteCode {

    bytes32 jobId = "6b88e0402e5d415eb946e528b8e0c7ba";
    
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant SwapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant FactoryV3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant SwapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant FactoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    IUniswapV3Factory public constant factoryV3 =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
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

    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant BNB = 0x418D75f65a02b3D53B2418FB8E1fe493759c7605;
    address public constant WXRP = 0x1E02E2eD139F5Baf6bfaD04c0E61EBb0110dA653;
    address public constant CURVE = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    
    address feeReceiver = vm.addr(1);
    address newFeeReceiver = vm.addr(2);
    address minter = vm.addr(3);
    address newMinter = vm.addr(4);
    address methodologist = vm.addr(5);
    address owner = vm.addr(6);
    address add1 = vm.addr(7);


    function deployContracts() public returns(
        LinkToken,
        MockApiOracle,
        IndexToken,
        MockV3Aggregator,
        IndexFactory,
        TestSwap
    ) {
        LinkToken link = new LinkToken();
        MockApiOracle oracle = new MockApiOracle(address(link));

        MockV3Aggregator ethPriceOracle = new MockV3Aggregator(
            18, //decimals
            2000e18   //initial data
        );

        IndexToken indexToken = new IndexToken();
        indexToken.initialize(
            "Anti Inflation",
            "ANFI",
            1e18,
            feeReceiver,
            1000000e18,
            //swap addresses
            WETH9,
            QUOTER,
            SwapRouterV3,
            FactoryV3,
            SwapRouterV2,
            FactoryV2
        );
        // indexToken.setMinter(minter);

        IndexFactory factory = new IndexFactory();
        factory.initialize(
            payable(address(indexToken)),
            // address(0),
            address(link),
            address(oracle),
            jobId,
            address(ethPriceOracle),
            //swap addresses
            WETH9,
            QUOTER,
            SwapRouterV3,
            FactoryV3,
            SwapRouterV2,
            FactoryV2
        );

        indexToken.setMinter(address(factory));

        // swap = new Swap();
        // dai = ERC20(DAI);
        // weth = IWETH(WETH9);
        // quoter = IQuoter(QUOTER);

        TestSwap testSwap = new TestSwap();

        // indexToken.transferOwnership(msg.sender);
        // link.transfer(msg.sender, link.balanceOf(address(this)););
        
        return (
            link,
            oracle,
            indexToken,
            ethPriceOracle,
            factory,
            testSwap
        );

    }

    function deployUniswap() public returns(address, address, address, address){
        // bytes memory bytecode = factoryByteCode;
        address factoryAddress = deployByteCode(factoryByteCode);
        address wethAddress = deployByteCode(WETHByteCode);
        address routerAddress = deployByteCodeWithInputs(routerByteCode, abi.encode(factoryAddress, wethAddress));
        address positionManagerAddress = deployByteCodeWithInputs(positionManagerByteCode, abi.encode(factoryAddress, wethAddress, 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707));
        // bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, abi.encode(_initData));
        return (factoryAddress, wethAddress, routerAddress, positionManagerAddress);
    }

    function deployByteCode(bytes memory bytecode) public returns(address){
        // bytes memory bytecode = hex"608060405234801561001057600080fd5b5060405161022338038061022383398181016040528101906100329190610054565b806000819055505061009e565b60008151905061004e81610087565b92915050565b60006020828403121561006657600080fd5b60006100748482850161003f565b91505092915050565b6000819050919050565b6100908161007d565b811461009b57600080fd5b50565b610176806100ad6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c80633bc5de30146100465780635b4b73a91461006457806373d4a13a14610080575b600080fd5b61004e61009e565b60405161005b9190610104565b60405180910390f35b61007e600480360381019061007991906100cc565b6100a7565b005b6100886100b1565b6040516100959190610104565b60405180910390f35b60008054905090565b8060008190555050565b60005481565b6000813590506100c681610129565b92915050565b6000602082840312156100de57600080fd5b60006100ec848285016100b7565b91505092915050565b6100fe8161011f565b82525050565b600060208201905061011960008301846100f5565b92915050565b6000819050919050565b6101328161011f565b811461013d57600080fd5b5056fea26469706673582212201b45f6ebd798180c4fea0a5c71d62272dc330a7727f9546c8b21961ea72bde4f64736f6c63430008010033";
        // bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, abi.encode(_initData));
        bytes memory bytecodeWithArgs = bytecode;
        address deployedContract;
        assembly {
            deployedContract := create(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs))
        }
        // assembly{
        //     mstore(0x0, bytecode)
        //     deployedContract := create(0,0xa0, 32)
        // }
        return deployedContract;
    }

    function deployByteCodeWithInputs(bytes memory bytecode, bytes memory _initData) public returns(address){
        // bytes memory bytecode = hex"608060405234801561001057600080fd5b5060405161022338038061022383398181016040528101906100329190610054565b806000819055505061009e565b60008151905061004e81610087565b92915050565b60006020828403121561006657600080fd5b60006100748482850161003f565b91505092915050565b6000819050919050565b6100908161007d565b811461009b57600080fd5b50565b610176806100ad6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c80633bc5de30146100465780635b4b73a91461006457806373d4a13a14610080575b600080fd5b61004e61009e565b60405161005b9190610104565b60405180910390f35b61007e600480360381019061007991906100cc565b6100a7565b005b6100886100b1565b6040516100959190610104565b60405180910390f35b60008054905090565b8060008190555050565b60005481565b6000813590506100c681610129565b92915050565b6000602082840312156100de57600080fd5b60006100ec848285016100b7565b91505092915050565b6100fe8161011f565b82525050565b600060208201905061011960008301846100f5565b92915050565b6000819050919050565b6101328161011f565b811461013d57600080fd5b5056fea26469706673582212201b45f6ebd798180c4fea0a5c71d62272dc330a7727f9546c8b21961ea72bde4f64736f6c63430008010033";
        // bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, abi.encode(_initData));
        bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, _initData);
        // bytes memory bytecodeWithArgs = bytecode;
        address deployedContract;
        assembly {
            deployedContract := create(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs))
        }
        // assembly{
        //     mstore(0x0, bytecode)
        //     deployedContract := create(0,0xa0, 32)
        // }
        return deployedContract;
    }
}