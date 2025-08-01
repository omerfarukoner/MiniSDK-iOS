# Teknik Zorluklar ve Kararlar

Bu döküman MiniSDK iOS geliştirme sürecinde alınan temel teknik kararları özetlemektedir.

## Ana Teknik Kararlar

### 1. Thread Safety Mimarisi
**Challenge**: iOS uygulamalarında Singleton olarak tasarlanan SDK'lar, örneğin Firebase gibi kütüphaneler farklı thread'lerden callback'ler gönderir. Aynı zamanda kullanıcı UI'dan da SDK'ya erişebilir. Bu durumda aynı anda birden fazla thread'in aynı veriyi değiştirmeye çalışması "race condition" yaratır ve uygulamanın crash olmasına sebep olabilir.  

  **Solution**:
  * SDK içinde concurrent DispatchQueue kullanıldı; okuma işlemleri paralel şekilde çalışarak performans artırıldı.
  * Yazma işlemleri için .barrier flag'li görevlerle thread-safe hale getirildi, race condition riski önlendi.
  * Loglama işlemleri UI thread'e uygun şekilde DispatchQueue.main üzerinden yapıldı.

### 2. Memory Management
**Challenge**: Eğer iki nesne birbirini güçlü referanslarla tutarsa, hiçbiri bellekten silinmez ve memory leak oluşur. Singleton pattern'de bu risk daha da yüksek çünkü singleton sürekli hayatta kalır. NotificationCenter observer'larının singleton içinde güçlü referansla tutulması, kolayca retain cycle yaratabilir.  

  **Solution**:
  * Observer closure'larında [weak self] kullanılarak retain cycle riski ortadan kaldırıldı.
  * deinit içinde NotificationCenter.removeObserver çağrılarak cleanup sağlandı.

### 3. Testability Design
**Challenge**: Singleton'lar test etmek zor çünkü global state tutarlar. Ayrıca hard-coded bağımlılıklar (print, UserDefaults gibi) mock'lanamaz, bu da unit test yazmayı zorlaştırır.  

  **Solution**:
  * Logger ve TokenStore gibi bağımlılıklar, protocol ile soyutlandı. Bu sayede üretim ve test ortamları için farklı implementasyonlarla esnek yapı sağlandı.
  * Production ortamı için varsayılan (default) implementasyonlar sunuldu; böylece SDK kullanıcılarının ekstra bir işlem yapmasına gerek kalmadı.
  * Test ortamları için ise, sadece test amaçlı kullanılmak üzere internal bir initializer tanımlandı. Bu initializer üzerinden mock nesneler geçilerek MiniSDK kolayca test edilebilir hale getirildi.

### 4. Firebase Entegrasyonu
**Challenge**: Firebase gibi büyük kütüphanelerle tight coupling (sıkı bağlılık) oluşturursanız, SDK'nız Firebase'e bağımlı hale gelir. Bu da esnekliği azaltır ve test etmeyi zorlaştırır.  

  **Solution**:
  * Firebase ile ilgili tüm kodlar AppDelegate içinde tutuldu.
  * MiniSDK sadece işlenmiş token ve payload ile ilgileniyor, doğrudan Firebase dependency'si yok.
  * MessagingDelegate ve UNUserNotificationCenterDelegate kullanılarak event'ler ayrıştırıldı. Bu sayede SDK core'u Firebase'i bilmiyor, sadece string token alıyor.

### 5. Base64 Implementation
**Challenge**: Bazı backend sistemler push token'ları Base64 formatında beklerken, diğerleri raw string formatını tercih ediyor. Mevcut kullanıcıları etkilemeden bu esnekliği sağlamak gerekiyor.  

  **Solution**:
  * initialize fonksiyonuna enableBase64 optional parametresi eklendi (default: false)
  * String için private extension ile Base64 dönüştürme yapıldı.

### 6. Error Handling
**Challenge**: iOS'ta hata yönetimi crash riski ile silent failure arasında denge kurmak lazım. Force unwrapping uygulamayı çökertirken, hataları görmezden gelmek de debug sürecini zorlaştırır.  

  **Solution**:
  * Tüm optional değerlerde guard let kullanılarak güvenli unwrap sağlandı ve crash riski önlendi.
  * Force unwrap (!) hiç kullanılmadı.
  * JSON serileştirmede try-catch ile hata durumunda boş JSON fallback'i döndürüldü.
  * weak self pattern'i ile memory leak'ler önlendi, nil check'ler ile güvenli execution sağlandı.

### 7. Payload Data Conversion
**Challenge**: Firebase'den gelen [AnyHashable: Any] türündeki notification payload'ını SDK'nın beklediği [String: Any] formatına güvenli şekilde dönüştürmek gerekiyor.  

  **Solution**:
  * convertToStringAnyDict fonksiyonu ile key'ler string'e cast edildi.
  * Type safety sağlanarak runtime crash'ler önlendi.

### 8. SDK State Management
**Challenge**: SDK'nın initialize edilip edilmediğinin kontrolü ve yeniden initialization durumunun yönetimi.  

  **Solution**:
  * isInitialized flag'i ile state tracking yapıldı.
  * Yeniden initialization durumunda warning log'u ile developer feedback sağlandı.

## Technical Debt

- API key'ler için şifreleme yok (production için gerekli)
- Token depolamada UserDefaults (Keychain daha güvenli)
- Console loglama (production'da filtreleme gerekli)
- Retry logic veya offline queue yok
- Sınırlı error scenario testleri

## Sonuç

Bu MiniSDK iOS implementasyonu sırasında, modern iOS geliştirmede karşılaşılan temel architectural challenge'ları ele alındı. Thread safety, memory management, testability gibi kritik konularda production-ready çözümler geliştirildi.
