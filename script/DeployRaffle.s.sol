pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    // function run() public {}

    // function deployContract() public returns (Raffle, HelperConfig) {
    //     HelperConfig helperConfig = new HelperConfig();
    //     // if we're on a local network deploy mocks, get local config
    //     // sepolia get sepolia config
    //     HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    //     vm.startBroadcast();
    //     Raffle raffle = new Raffle(
    //         config.entranceFee,
    //         config.interval,
    //         config.vrfCoordinator,
    //         config.gasLane,
    //         config.subscriptionId,
    //         config.callbackGasLimit
    //     );
    //     vm.stopBroadcast();
    //     return (raffle, helperConfig);
    // }
    function run() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        console.log("Checking VRFCoordinator:", config.vrfCoordinator);
        require(config.vrfCoordinator != address(0), "VRFCoordinator address cannot be zero");

        vm.startBroadcast();
        Raffle raffle = new Raffle( 
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
