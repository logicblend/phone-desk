<div align="center">
  <img src="https://raw.githubusercontent.com/bilo-developer/phone-desk/main/assets/app_icon.ico" width="100" />
  <h1>📱 Phone Desk</h1>
  <p><strong>Bilgisayarınızı Telefonunuzdan Canlı ve Kesintisiz Yönetin!</strong></p>
</div>

<br>

**Phone Desk**, bilgisayarınızı akıllı telefonunuz veya tabletiniz üzerinden (yerel ağ bağlantısı ile) tam kapsamlı olarak kontrol etmenizi sağlayan güçlü, estetik ve ultra-düşük gecikmeli bir masaüstü uygulamasıdır. Herhangi bir ekstra mobil uygulama kurmanıza gerek kalmaz; bilgisayarın size sunduğu yerel web adresine tarayıcınızdan girmeniz yeterlidir!

---

## 🌟 Öne Çıkan Özellikler

### 🎮 Canlı Ekran Kontrolü (Sıfır Gecikme!)
Bilgisayar ekranınızı **gerçek zamanlı (MJPEG Stream)** mimarisiyle telefonunuzdan canlı izleyin. 
- **Akıcılık (FPS) Seçenekleri:** İnternet ağınızın durumuna göre 15, 30, 45 veya 60 FPS hızlarında izleyebilirsiniz.
- **Dinamik Çözünürlük (Kalite):** Gecikmeyi tamamen sıfırlamak için 480p, mükemmel netlik için 1080p gibi çözünürlük modları arasında anında geçiş yapabilirsiniz.
- **Tam Ekran (Fullscreen) Desteği:** Telefonunuzu yatay (landscape) moda alarak cihazınızın tüm ekranını kullanarak bilgisayarınızı yönetin.

### 🖱️ Touchpad (Dokunmatik Fare ve Klavye)
Telefonunuzun ekranını tıpkı bir dizüstü bilgisayar touchpad'i gibi kullanın. Sağ tık, sol tık ve metin gönderme işlemlerini tek dokunuşla halledin.

### 📂 Dosya Yöneticisi
Bilgisayarınızın tüm sabit disklerinde (C:\, D:\ vb.) telefonunuz üzerinden özgürce dolaşın.
- PC'nizdeki dosyaları anında telefonunuza indirin.
- Telefonunuzdan bilgisayarınıza tek tıkla **Dosya Yükleyin** (Upload).

### 🎛️ Özelleştirilebilir Stream Deck
Özel kısa yollar oluşturun ve telefonunuzu profesyonel bir kontrol paneline (Stream Deck) dönüştürün. Uygulama başlatma, ses açma-kısma, medya kontrolleri ve daha fazlasını uzaktan tek tıkla halledin.

### 🔒 Yerel Güvenlik
Uygulama arka planda (Sistem tepsisinde) çalışır ve açılırken size özel 6 haneli **Güvenlik Şifresi** üretir. Ağınızdaki herkes değil, yalnızca şifreye sahip olan kişi bilgisayara erişebilir.

---

## 🚀 Kurulum ve Başlangıç

1. Sağ taraftaki **Releases** bölümünden **PhoneLink_Installer.exe** dosyasını indirin.
2. Kurulumu tamamlayıp uygulamayı başlatın (Sistem tepsisinde yeşil bir telefon ikonuna dönüşecektir).
3. İkona sağ tıklayıp **QR Kodu Göster** deyin.
4. Çıkan QR kodu telefonunuzun kamerası ile okutun veya yazan adresi tarayıcınıza girin.
5. Bilgisayarda yazan güvenlik şifresini girip giriş yapın!

*(Not: Bilgisayarınız ve telefonunuzun aynı Wi-Fi (Yerel Ağ) üzerinde bağlı olması gerekmektedir.)*

---

## 🛠️ Geliştirici ve Mimari Notları

- **Frontend:** Pure HTML/CSS (Vanilla Javascript), Tailwind ile harmanlanmış ultra-modern, karanlık mod (dark theme) destekli duyarlı web arayüzü.
- **Backend (API):** Dart ve Flutter çekirdeği ile yazılmış multithread destekli yerel web sunucusu.
- **Görüntü İşleme:** Dart FFI ve Win32 kütüphaneleri kullanılarak donanım üzerinden "BitBlt" teknolojisi ile anlık ekran yakalama ve MJPEG stream.
