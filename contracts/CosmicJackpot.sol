// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// --- SON DÜZELTME: Tüm Chainlink import yolları, doğru olan /src/ klasörünü içerecek şekilde güncellendi ---
import {VRFCoordinatorV2_5Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2_5Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title CosmicJackpot
 * @notice A Web3 space-themed slot game using Chainlink VRF v2.5 for fairness.
 * @dev Designed for Base Sepolia testnet.
 */
contract CosmicJackpot is VRFConsumerBaseV2, Ownable {
    // --- Events ---
    event SpinRequested(uint256 indexed requestId, address indexed player);
    event SpinFulfilled(
        uint256 indexed requestId,
        address indexed player,
        uint256 amount,
        bool won,
        uint8[3] symbols
    );
    event JackpotWon(address indexed winner, uint256 amount);

    // --- State Variables ---

    VRFCoordinatorV2_5Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    mapping(uint256 => address) public s_requestIdToPlayer;

    // Game Mechanics
    uint256 public jackpotBalance;
    uint256 public feeBalance;
    uint8 public constant GAME_FEE_PERCENT = 5;
    uint8 private constant NUM_SYMBOLS = 4; // 0: Star, 1: Planet, 2: Ship, 3: Comet

    // Spin History
    struct SpinResult {
        address player;
        uint256 amount; // Jackpot size at the time of spin
        bool won;
        uint8[3] symbols;
        uint256 timestamp;
    }
    SpinResult[] public s_spinHistory;

    /**
     * @param vrfCoordinatorV2 Base Sepolia VRF v2.5 Coordinator address
     * @param subscriptionId Your Chainlink VRF v2.5 subscription ID
     * @param keyHash The gas lane key hash
     */
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinatorV2) Ownable(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2_5Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
    }

    /**
     * @notice Allows a player to spin the slot machine by sending ETH.
     */
    function spin() external payable {
        require(msg.value > 0.00001 ether, "Spin value too low");

        uint256 feeAmount = (msg.value * GAME_FEE_PERCENT) / 100;
        jackpotBalance += (msg.value - feeAmount);
        feeBalance += feeAmount;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToPlayer[requestId] = msg.sender;
        emit SpinRequested(requestId, msg.sender);
    }

    /**
     * @notice Callback function for Chainlink VRF to deliver the random result.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address player = s_requestIdToPlayer[_requestId];
        require(player != address(0), "Request not found or completed");
        delete s_requestIdToPlayer[_requestId];

        uint256 randomValue = _randomWords[0];
        uint8[3] memory symbols;
        symbols[0] = uint8(randomValue % NUM_SYMBOLS);
        symbols[1] = uint8((randomValue / NUM_SYMBOLS) % NUM_SYMBOLS);
        symbols[2] = uint8((randomValue / (NUM_SYMBOLS * NUM_SYMBOLS)) % NUM_SYMBOLS);

        bool hasWon = (symbols[0] == symbols[1] && symbols[1] == symbols[2]);
        uint256 jackpotAmountAtSpin = jackpotBalance;

        if (hasWon) {
            uint256 amountToTransfer = jackpotBalance;
            jackpotBalance = 0;
            (bool success, ) = player.call{value: amountToTransfer}("");
            require(success, "Failed to send jackpot");
            emit JackpotWon(player, amountToTransfer);
        }

        _storeSpinHistory(player, jackpotAmountAtSpin, hasWon, symbols);
        emit SpinFulfilled(_requestId, player, jackpotAmountAtSpin, hasWon, symbols);
    }

    function _storeSpinHistory(address player, uint256 amount, bool won, uint8[3] memory symbols) private {
        if (s_spinHistory.length >= 50) {
            for (uint i = 0; i < s_spinHistory.length - 1; i++) {
                s_spinHistory[i] = s_spinHistory[i+1];
            }
            s_spinHistory.pop();
        }
        s_spinHistory.push(SpinResult(player, amount, won, symbols, block.timestamp));
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = feeBalance;
        require(amount > 0, "No fees to withdraw");
        feeBalance = 0;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }

    function getLatestSpins(uint256 count) external view returns (SpinResult[] memory) {
        uint256 numSpins = s_spinHistory.length;
        if (count > numSpins) count = numSpins;
        SpinResult[] memory latestSpins = new SpinResult[](count);
        for (uint256 i = 0; i < count; i++) {
            latestSpins[i] = s_spinHistory[numSpins - 1 - i];
        }
        return latestSpins;
    }
}