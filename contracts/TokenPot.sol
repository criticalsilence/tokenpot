// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenPot is ReentrancyGuard {
    address public owner; // Kontratın sahibi (operatör ücretleri bu adrese gidecek)
    uint256 public constant OPERATOR_FEE_PERCENT = 5; // %5 operatör ücreti
    uint256 public minimumBet;

    // Yaklaşık 1/10 kazanma şansı için (0-9 arası rastgele sayı, 0 gelirse kazanır)
    uint256 private constant WIN_CHANCE_MODULO = 10;
    uint256 private constant WINNING_NUMBER = 0; // Bu sayıya denk gelirse kazanır

    event SpinResult(
        address indexed player,
        uint256 betAmount,
        bool didWin,
        uint256 playerPayoutAmount,
        uint256 operatorPayoutAmount,
        uint8[3] resultSymbols // Görsel amaçlı semboller
    );

    constructor(uint256 _minimumBet) {
        owner = msg.sender;
        minimumBet = _minimumBet;
    }

    function betAndSpin() public payable nonReentrant {
        require(msg.value >= minimumBet, "Bet is below minimum");
        
        // GÜVENLİK UYARISI: Aşağıdaki rastgele sayı üretimi GÜVENLİ DEĞİLDİR.
        // Gerçek bir jackpot sistemi için Chainlink VRF kullanılmalıdır.
        // Bu sadece bir DEMO ve geliştirme amaçlıdır.
        uint256 pseudoRandomForWin = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, address(this).balance, block.number)));
        
        bool didWin = (pseudoRandomForWin % WIN_CHANCE_MODULO) == WINNING_NUMBER;

        uint256 playerPayout = 0;
        uint256 operatorPayout = 0;
        // Oyuncunun bahsi zaten kontrat bakiyesine eklendiği için address(this).balance doğru havuz miktarını verir.
        uint256 currentPoolBalanceIncludingCurrentBet = address(this).balance; 

        if (didWin) {
            // Havuzun %95'i oyuncuya, %5'i operatöre
            playerPayout = (currentPoolBalanceIncludingCurrentBet * (100 - OPERATOR_FEE_PERCENT)) / 100;
            operatorPayout = currentPoolBalanceIncludingCurrentBet - playerPayout; // Kalan %5

            if (playerPayout > 0) {
                (bool successPlayer, ) = msg.sender.call{value: playerPayout}("");
                require(successPlayer, "Failed to send prize to player");
            }
            if (operatorPayout > 0) {
                (bool successOperator, ) = owner.call{value: operatorPayout}("");
                require(successOperator, "Failed to send fee to owner");
            }
        } else {
            // Kaybetme durumunda, oyuncunun bahsi havuzda kalır. Operatör bu durumda doğrudan bir pay almaz.
            // Eğer her bahisten %5 alınacaksa burası değişmeliydi, ancak isteğiniz jackpot'tan pay olduğu için böyle bırakıyoruz.
        }

        // Görsel amaçlı rastgele semboller üret (kazanıp kazanmadığını etkilemez)
        uint256 pseudoRandomForSymbols = uint256(keccak256(abi.encodePacked(pseudoRandomForWin, block.coinbase, msg.sender))); // Farklı bir seed
        uint8[3] memory symbols;
        symbols[0] = uint8(pseudoRandomForSymbols % 11); // 11: SYMBOLS_EMOJI.length
        symbols[1] = uint8((pseudoRandomForSymbols / 11) % 11);
        symbols[2] = uint8((pseudoRandomForSymbols / 11 / 11) % 11);
        
        emit SpinResult(msg.sender, msg.value, didWin, playerPayout, operatorPayout, symbols);
    }

    // Kontrat sahibinin, birikmiş olabilecek (şu anki mantıkta birikmez)
    // veya doğrudan gönderilemeyen ücretleri çekmesi için.
    function withdrawOwnerFees() public nonReentrant {
        require(msg.sender == owner, "Not the owner");
        // Mevcut durumda, kazanç anında ücretler sahibe transfer edildiği için bu fonksiyon
        // genellikle kontratta ETH bırakmaz. Ancak, doğrudan kontrata ETH gönderilmesi gibi
        // nadir durumlar için veya gelecekteki farklı ücret modelleri için bir güvence olabilir.
        uint256 balance = address(this).balance;
        if (balance > 0) {
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