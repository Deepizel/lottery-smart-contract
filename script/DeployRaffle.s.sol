pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployContract();
    }

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
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        console.log("Checking VRFCoordinator:", config.vrfCoordinator);
        require(config.vrfCoordinator != address(0), "VRFCoordinator address cannot be zero");
        if (config.subscriptionId == 0){
            // create a new subscription here 
            CreateSubscription createSubcription = new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator) = createSubcription.createSubscription(config.vrfCoordinator);
        
        // fund it with LINK 
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);

        
        }
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
    AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(address(raffle),config.vrfCoordinator,config.subscriptionId);
        return (raffle, helperConfig);
    }
}
