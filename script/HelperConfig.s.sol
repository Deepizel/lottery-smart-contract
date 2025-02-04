// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract codeSnippets {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
     uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, codeSnippets {
    error HelperConfig__InvalidChainId();
    
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0))
        {
            return networkConfigs[chainId];
        }else if( chainId == LOCAL_CHAIN_ID)
        {
            getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
           
        }
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //1e16
                interval: 30, //30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
                callbackGasLimit: 500000,
                subscriptionId: 0
            });
    }

// this will not be pure cos we're making some changes here 
      function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // ?check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0))
        return localNetworkConfig;
    }
}
