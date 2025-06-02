// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenPot is ReentrancyGuard {
    address public owner; 
    uint256 public constant OPERATOR_FEE_PERCENT = 5; 
    uint256 public minimumBet;

    uint256 private constant WIN_CHANCE_MODULO = 10; // Kazanma olasılığı için bölen (10'da 1)
    uint256 private constant WINNING_NUMBER = 0;    // Bu sayıya denk gelirse kazanır
    uint8 private constant NUM_WINNING_SYMBOLS = 5; // 🍒, 🍋, 🍊, 🍇, ⭐ (indisler 0-4)

    event SpinResult(
        address indexed player,
        uint256 betAmount,
        bool didWin,
        uint256 playerPayoutAmount,
        uint256 operatorPayoutAmount,
        uint8[3] resultSymbols 
    );

    constructor(uint256 _minimumBet) {
        owner = msg.sender;
        minimumBet = _minimumBet;
    }

    function betAndSpin() public payable nonReentrant {
        require(msg.value >= minimumBet, "Bet is below minimum");
        
        // GÜVENLİK UYARISI: Zincir içi rastgelelik GÜVENLİ DEĞİLDİR. Demo amaçlıdır.
        // Gerçek kullanım için Chainlink VRF gibi bir oracle çözümü şarttır.
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, address(this).balance, block.number)));
        
        bool didWin = (pseudoRandomBase % WIN_CHANCE_MODULO) == WINNING_NUMBER;

        uint256 playerPayout = 0;
        uint256 operatorPayout = 0;
        uint256 currentPoolBalanceIncludingCurrentBet = address(this).balance; 

        uint8[3] memory symbols;

        if (didWin) {
            playerPayout = (currentPoolBalanceIncludingCurrentBet * (100 - OPERATOR_FEE_PERCENT)) / 100;
            operatorPayout = currentPoolBalanceIncludingCurrentBet - playerPayout;

            if (playerPayout > 0) {
                (bool successPlayer, ) = msg.sender.call{value: playerPayout}("");
                require(successPlayer, "Failed to send prize to player");
            }
            if (operatorPayout > 0) {
                (bool successOperator, ) = owner.call{value: operatorPayout}("");
                require(successOperator, "Failed to send fee to owner");
            }

            // Kazanan spin için sembolleri ayarla: 3 aynı kazanan meyve
            uint256 winningSymbolSeed = uint256(keccak256(abi.encodePacked(pseudoRandomBase, msg.sender))); // Farklı bir seed
            uint8 winningSymbolIndex = uint8(winningSymbolSeed % NUM_WINNING_SYMBOLS); // 0 ile 4 (dahil) arası bir kazanan sembol seç
            symbols[0] = winningSymbolIndex;
            symbols[1] = winningSymbolIndex;
            symbols[2] = winningSymbolIndex;

        } else {
            // Kaybeden spin için rastgele (ve büyük olasılıkla eşleşmeyen) semboller
            uint256 losingSymbolsSeed = uint256(keccak256(abi.encodePacked(pseudoRandomBase, block.coinbase))); // Farklı bir seed
            symbols[0] = uint8(losingSymbolsSeed % 11);          // 11: SYMBOLS_EMOJI.length (ön yüzdeki)
            symbols[1] = uint8((losingSymbolsSeed / 11) % 11);
            symbols[2] = uint8((losingSymbolsSeed / 11 / 11) % 11);

            // Kaybeden spinde 3 aynı kazanan sembol gelme ihtimalini çok düşürmek için
            // (veya garanti etmek için) ekstra kontrol eklenebilir, ama demo için bu yeterli.
            // Önemli olan didWin bayrağıdır.
        }
        
        emit SpinResult(msg.sender, msg.value, didWin, playerPayout, operatorPayout, symbols);
    }

    function withdrawOwnerFees() public nonReentrant {
        require(msg.sender == owner, "Not the owner");
        uint256 balance = address(this).balance;
        if (balance > 0) {
            // Bu fonksiyon sadece kontratta yanlışlıkla kalan ETH'yi çekmek için kullanılabilir,
            // çünkü operatör ücreti zaten kazanç anında sahibine gönderiliyor.
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Withdrawal failed");
        }
    }

    function setMinimumBet(uint256 _newMinimumBet) public {
        require(msg.sender == owner, "Not the owner");
        minimumBet = _newMinimumBet;
    }

    receive() external payable {}
    fallback() external payable {}
}