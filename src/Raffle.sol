// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title A Simple Raffle Contract
 * @author Victor Ekundayo
 * @notice this contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 s_raffleState);
    // type declarations

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // state varibles
    // @dev the duration of the lottery in seconds
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint256 private s_lastTimeStamp;
    address private s_winner;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    /* Events */

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        // require(msg.value >= !i_entranceFee,)
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        // events makes migration faster especially when redeploying smart contract
        // makes front end indexing easier
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink nodes will call to use
     * if the lottery is ready to have a winner picked.
     * the following should be true in order for upkeepNeeded to be true;
     * 1 the time interval has passed between raffle runs
     * 2 the lottery isopen
     * 3 the contract has eth (has players)
     * 4 implicity, your sub has LINK
     * @param -ignored'
     * @return upkeepNeeded -true if time to restart the lottery
     * @return - ignored
     *
     */
    function checkUpkeep(bytes memory /* checkdata*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData */ )
    {
        // check to see if time has passed
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }
    // get a random number
    // use random number to pick a winner
    // be automatically called

    function performUpkeep(bytes calldata /* performData */ ) external {
        // check to see if time has passed
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        // Get random number
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callBackGasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        // fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // CEI: checks, effects, interactions
        // get the random words
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_winner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    // getters
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
