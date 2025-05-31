// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // OpenZeppelin'den ReentrancyGuard'ı import ediyoruz

contract TokenPot is ReentrancyGuard {
    address public owner;
    uint256 public operatorFeePercent = 5; // %5 operatör ücreti
    uint256 public minimumBet;

    // Aktif spin isteklerini ve oyuncularını takip etmek için mapping
    // Bu, Chainlink VRF gibi bir asenkron rastgelelik kaynağı kullanılıyorsa daha anlamlı olur.
    // Mevcut senkronize _resolveSpin için zorunlu değil ama iyi bir pratik.
    mapping(bytes32 => address) public spinRequests;

    // Event'ler: Blockchain üzerinde gerçekleşen önemli olayları loglamak ve
    // ön yüz (frontend) tarafından dinlenebilmek için kullanılır.
    event SpinRequested(bytes32 indexed requestId, address indexed player);
    event SpinResult(
        bytes32 indexed requestId,
        address indexed player,
        uint256 betAmount,
        uint256 prizeAmount,
        uint8[3] resultSymbols // Dönen sembollerin indisleri
    );

    constructor(uint256 _minimumBet) {
        owner = msg.sender; // Kontratı deploy eden kişi sahibi olur
        minimumBet = _minimumBet;
    }

    // Oyuncunun bahis yapıp makaraları çevirdiği ana fonksiyon
    // 'payable' anahtar kelimesi, bu fonksiyona ETH gönderilebileceği anlamına gelir.
    // 'nonReentrant' değiştiricisi, re-entrancy saldırılarına karşı koruma sağlar.
    function betAndSpin() public payable nonReentrant {
        require(msg.value >= minimumBet, "Bet is below minimum"); // Gönderilen ETH'nin minimum bahisten fazla olmasını kontrol et

        // Basit bir requestId oluşturma (gerçek bir uygulamada daha güvenli bir yöntem gerekebilir)
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number));
        spinRequests[requestId] = msg.sender;

        emit SpinRequested(requestId, msg.sender); // Spin isteği event'ini yayınla

        // Spin sonucunu hemen hesapla ve işle (senkronize)
        _resolveSpin(requestId, msg.value);
    }

    // Spin sonucunu belirleyen ve ödemeyi yapan özel (private) fonksiyon
    function _resolveSpin(bytes32 requestId, uint256 betAmount) private {
        address player = spinRequests[requestId];
        require(player != address(0), "Invalid request or already processed"); // Geçerli bir istek mi kontrol et

        // İsteği işlendi olarak işaretle (tekrar işlenmesini önlemek için)
        // Eğer Chainlink VRF gibi bir yapı kullanılsaydı bu adım daha kritik olurdu.
        delete spinRequests[requestId]; 

        // GÜVENLİK UYARISI: Aşağıdaki rastgele sayı üretimi blockchain üzerinde
        // tahmin edilebilir ve GÜVENLİ DEĞİLDİR. Bu sadece bir DEMO içindir.
        // Gerçek bir para ile çalışan slot makinesi için MUTLAKA
        // Chainlink VRF gibi zincir dışı, doğrulanabilir bir rastgelelik kaynağı kullanılmalıdır.
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(requestId, block.prevrandao, block.timestamp)));

        uint8[3] memory symbols; // 3 makara için sembol indisleri
        symbols[0] = uint8(pseudoRandom % 11);          // 0-10 arası bir sayı (11 sembolümüz olduğunu varsayıyoruz)
        symbols[1] = uint8((pseudoRandom / 11) % 11);
        symbols[2] = uint8((pseudoRandom / 11 / 11) % 11);

        uint256 prizeAmount = 0;

        // Basit Kazanç Mantığı: 3 aynı "kazanan" sembol (0-4 arası indisler kazanan semboller olsun)
        if (symbols[0] < 5 && symbols[0] == symbols[1] && symbols[1] == symbols[2]) {
            uint multiplier = _getMultiplier(symbols[0]); // Sembole göre çarpan al
            uint grossPrize = betAmount * multiplier; // Brüt ödül
            uint operatorFee = (grossPrize * operatorFeePercent) / 100; // Operatör ücreti hesapla
            prizeAmount = grossPrize - operatorFee; // Net ödül

            // Oyuncuya kazancını gönder
            if (prizeAmount > 0) {
                (bool success, ) = player.call{value: prizeAmount}("");
                require(success, "Failed to send prize to player");
            }
        }

        // Spin sonucu event'ini yayınla
        emit SpinResult(requestId, player, betAmount, prizeAmount, symbols);
    }

    // Sembol indisine göre kazanç çarpanını döndüren özel fonksiyon
    function _getMultiplier(uint8 symbolIndex) private pure returns (uint) {
        if (symbolIndex == 0) return 5;  // Örneğin: 🍒 ise 5x
        if (symbolIndex == 1) return 10; // Örneğin: 🍋 ise 10x
        if (symbolIndex == 2) return 15; // Örneğin: 🍊 ise 15x
        if (symbolIndex == 3) return 20; // Örneğin: 🍇 ise 20x
        if (symbolIndex == 4) return 50; // Örneğin: ⭐ ise 50x
        return 0; // Diğer semboller için kazanç yok
    }

    // Kontrat sahibinin biriken operatör ücretlerini çekmesi için fonksiyon
    function withdrawFees() public nonReentrant {
        require(msg.sender == owner, "Not the owner");
        // Bu fonksiyonun mantığı daha sonra eklenebilir. 
        // Örneğin, kontratta biriken operatör payını sahibin adresine gönderebilir.
        // Şu an için, kontratın bakiyesinden direkt çekim yapmıyoruz,
        // çünkü operatör ücreti `prizeAmount` hesaplanırken zaten düşülüyor.
        // Eğer her bahisten bir pay alınacaksa veya farklı bir ücret modeli varsa bu fonksiyonun içi doldurulur.
        // Şimdilik sadece sahibinin çağırabileceği bir yer tutucu.
    }
}