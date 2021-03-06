# Rfid_NodeMcu_Antipass_Tarihli
WEB KONTROLLÜ ARDUİNO ( NODE MCU ) KARTLI GEÇİŞ SİSTEMİ RFİD + MYSQL + WEBSİTESİ + ANTİPASS + GEÇEN SÜRE

https://www.kirmiziyuz.com/arduino/web-kontrollu-arduino-node-mcu-kartli-gecis-sistemi-rfid-mysql-websitesi-antipass-gecen-sure.html

<p align="center">
  <img src="https://kirmiziyuz.com/wp-content/uploads/2018/12/Rfid.png"/>
</p>


<p align="center">
  <a href="https://www.youtube.com/watch?v=HsPRCeOBuEA "Rfid-NodeMcu-Antipass-Sql" target="_blank">
  <img src="https://kirmiziyuz.com/wp-content/uploads/2021/06/youtube.jpg"/>
 </a>
</p>

Node MCU ile yapmış olduğum RFid projemi sizler ile paylaşıyorum. Projede 2 Kart okutma ünitesi mevcuttur. Bunlardan biri giriş ve biri de çıkış için kullanılıyor. Proje kodları internet sitesi ve sql dosyaları en aşağıda bulabilirsiniz.

internet sitesi ve sql ayarları için :

www/ewcfg10.php dosyasındaki 46-50 satırları arasındaki db ayarları yapılmalıdır.
ayrıca site girişi için şifre bilgileri 194-195. satırdaki yerden değiştirilebilinir.

Kullanıcı Adı: Admin
Password: Admin

olarak ayarlanmıştır.

ayrıca www/node.php dosyasında 8-10 arasındaki db bilgileri ile
19. satırdaki db_user_name düzenlenmelidir.

 
Ayrıca Programdaki 26-27. satırlarda SSID ve şifre bilgileri düzenlenmeli ayrıca node.php nin yolunu gösterdiğimiz. 165. satırı da es geçmeyiniz.

Son önemli not: 29. ve 30. satırdaki kodlar dan biri giriş kartı için diğeri de çıkış kartı için kullanılmaktadır. Programları yüklerken bunu unutmayınız.

# Web Site görüntüleri

<p align="center">
  <img src="https://kirmiziyuz.com/wp-content/uploads/2018/12/1-e1543776088332.png"/>
  <img src="https://www.kirmiziyuz.com/wp-content/uploads/2018/12/2.png"/>
  <img src="https://www.kirmiziyuz.com/wp-content/uploads/2018/12/3-1.png"/>
</p>                                                                          

                                                                          
# Node MCU Programı
```
/*
Name:    RFID.ino
Created: 11/18/2018 10:51:11 PM
Author:  Adem KIRMIZIYÜZ
*/
#include <string.h>

// LCD Kütüphanesi ekleniyor
// SDA : D2, SCL : D1

#include <LiquidCrystal_I2C.h>
#include <Wire.h>
LiquidCrystal_I2C lcd(0x27, 16, 2);

// RfId Kütüphanesi ekleniyor
#include <MFRC522.h>
MFRC522 rfid(D8, D4);
// RfId ID numarasını tutmak için değişken tanımlıyoruz
char numTag[5] = { 0 };

// NodeMCU ESP8266 Kütüphanesi ekleniyor
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

const char* ssid = "WİFİ SSID";
const char* password = "PASSWORD";

const int type = 0;// Giriş Cihazı İçin Atılması gereken Parametre
//const int type = 1; // Çıkış Cihazı İçin Atılması gereken Parametre

// Pinler
#define BUZZER_PIN D3
#define ROLE_PIN D0

void setup() {
  //Pin modlarını ayarlayan method çağrılıyor
  initPinModes();
  //LCD ayarlarını yapan method çağrılıyor
  initLCD();
  //RfId ayarları yapan method çağrılıyor
  initRFID();
  //Wireless ayarları yapan method çağrılıyor
  initWireless();
  //LCD ye ana ekran mesajı yazdıran method çağrılıyor
  lcdClearAnaEkran();
}

void loop() {
  //RfId okuyan method çağrılıyor
  checkRfId();
}


// Wireless bağlantı ayarlarını yapan method
void initWireless() {
  WiFi.begin(ssid, password); // Wireless başlatılıyor
  Serial.print("Baglaniliyor :  "); //Seriale bilgi gönderiliyor
  Serial.print(ssid); Serial.println(" ...");
  lcd.clear(); // LCD temizleniyor
  lcd.home(); // LCD cursoru ilk pozisyona getiriliyor
  lcd.println("WiFi Baglaniyor:"); // LCD ye yazılıyor
  lcd.blink_on(); // LCD cursor yanıp sönme konumuna alınıyor 
  int i = 0; // Geçen süreyi saymak için değişken tanımlanıyor
  while (WiFi.status() != WL_CONNECTED) { // Wireless bağlanana kadar dönecek olan döngü başlatılıyor
    delay(1000); // 1sn beklenşyor.
    lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
    Serial.print(++i); Serial.print(' '); // Seriale geçen sn yazılıyor
    lcd.print(i); // LCD ye geçen süre yazılıyor
  }
  lcd.blink_off(); // LCD cursor yanıp sönme konumundan çıkarılıyor 
  lcd.clear(); // LCD temizleniyor
  lcd.home(); // LCD cursoru ilk pozisyona getiriliyor
  lcd.print("Baglandi"); // LCD ye yazılıyor
  lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
  lcd.print(WiFi.localIP()); // LCD ye DHCP den alınan IP adresi yazılıyor
  Serial.print("IP Adresş :\t"); //Seriale bilgi gönderiliyor
  Serial.println(WiFi.localIP()); // Seriale DHCP den alınan IP adresi yazılıyor
  delay(3000); // 3 sn beklenşyor
}


// RfId kart okuma methodu
void checkRfId()
{
  if (!rfid.PICC_IsNewCardPresent()) return; // Çoklu okumada ilk okunan kart değilse methodtan çıkılıyor
  if (!rfid.PICC_ReadCardSerial()) return; // Okunan kartın seri numarası alınamıyorsa methodtan çıkılıyor
  String content = ""; // RfId seri numarasını tutmak için değişken tanımlanıyor
  for (byte i = 0; i < rfid.uid.size; i++) { // Array byte olarak gelen seri numarası Strin turune çevirmek için döngü ile karakter karakter stringe ekleniyor
    content.concat(String(rfid.uid.uidByte[i] < 0x10 ? " 0" : " "));
    content.concat(String(rfid.uid.uidByte[i], HEX));
  }
  content.trim(); // Alınan seri numarasının başındaki ve sonundaki boş karakterler temizleniyor
  rfid.PICC_HaltA(); // RfId sonlandırılıyor
  rfid.PCD_StopCrypto1(); // RfId sonlandırılıyor
  printSerialNum(content); // Okunan seri nuamrası ekrana basılması için ilgili methoda gönderiliyor
  lcd.clear(); // LCD temizleniyor
  String ret = checkAccess(content); // Okunan seri numarası veritabanı kontrolü için ilgili methoda gönderiliyor
  if (ret != "0" && ret != NULL && ret != "") // veritabanınadan gelen sonuç 0,NULL ve Empty değilse kartın doğru olduğu anlaşılıyor
  {
    // Kart doğru
    if (type==0) {
      lcd.print("Hosgeldiniz"); // LCD ye yazılıyor
      lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
      lcd.print(ret); // LCD veritabanından dönen isim yazılıyor
    } else {
      String name = getValue(ret, '|', 0);
      String sure = getValue(ret, '|', 1);
      lcd.print(" Gule Gule "); // LCD ye yazılıyor
      lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
      lcd.print(sure); // LCD veritabanından dönen isim yazılıyor
    }
    digitalWrite(BUZZER_PIN, HIGH); // Buzzer açılıyor
    delay(300); // 0.3 sn bekleniyor
    digitalWrite(BUZZER_PIN, LOW); // Buzzer kapatılıyor
    delay(1000); // 1sn bekleniyor
    kapiAcKapat(); // Kapıyı açıp kapatacak method çağrılıyor
    lcdClearAnaEkran(); //LCD ye ana ekran mesajı yazdıran method çağrılıyor
  }
  else {
    // Kart hatalı
    lcd.print("Kart Bulunamadi!"); // LCD ye yazılıyor
    lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
    lcd.print("Izinsiz Giris!"); // LCD ye yazılıyor

    for (int i = 0; i < 3; i++) // Buzzer için 3 defa dönülüyor
    {
      digitalWrite(BUZZER_PIN, HIGH); // Buzzer açılıyor
      delay(200); // 0.2 sn bekleniyor
      digitalWrite(BUZZER_PIN, LOW); // Buzzer kapatılıyor
      delay(200); // 0.2 sn bekleniyor
    }
    delay(2000); // 2 sn bekleniyor
    lcdClearAnaEkran(); //LCD ye ana ekran mesajı yazdıran method çağrılıyor
  }
}


// Kapıyı açıp kapatacak method
void kapiAcKapat()
{
  lcd.clear(); // LCD temizleniyor
  lcd.print("Kapi Aciliyor"); // LCD ye yazılıyor
  lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
  lcd.print("Bekleyin...."); // LCD ye yazılıyor
  delay(1000); // 1 sn bekleniyor
  digitalWrite(ROLE_PIN, HIGH); // Röle çekiliyor
  for (int i = 5; i > 0; i--) // 5 sn boyunca saymak için döngü başlatılıyor
  {
    lcd.clear(); // LCD temizleniyor
    lcd.print("Kapi Kapaniyor"); // LCD ye yazılıyor
    lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
    //if (i == 10) // Eğer sn 5 ise satır başından yazıyoruz
      lcd.print(i); // LCD sn yazılıyor
    //else
    //{
    //  lcd.print(" "); // Eğer sn 10 değilse satır başından boşluk bırakıp yazıyoruz
    //  lcd.print(i); // LCD sn yazılıyor
    //}
    lcd.print(" Acele Edin "); // LCD ye yazılıyor
    delay(1000); // 1 sn bekleniyor
  }
  digitalWrite(ROLE_PIN, LOW); // Röle bırakılıyor
}


// Veritabanından card kontrolü yapan method
String checkAccess(String seriNum)
{
  HTTPClient http; // NodeMCU nun HTTPClient nesnesinden bir örnek alınıyor
  String postData; // Web sitesindeki php'ye göndereceğimiz veri için string tanımlıyoruz
  postData = "type=" + String(type) +"&cardid=" + seriNum; // ilgili stringe verimizi ekliyoruz. cardid field'i ile
  http.begin("http://www.Domain.com/node.php"); // HTTPClient e URL veriyoruz
  http.addHeader("Content-Type", "application/x-www-form-urlencoded"); // HTTP Header olarak Content-Type i form olarak ayarlıyoruz
  int httpCode = http.POST(postData); // POST ile veriyi ilgili URL ye gönderiyoruz ve dönen response kodunu integer bir değişkene alıyoruz
  String payload; // Dönen veriyi almak için string bir değişken tanımlıyoruz
  if (httpCode != 200) // http response kodu 200 değil donecek kodu 0 veriyoruz
  {
    payload = "0";
  }
  else {
    payload = http.getString(); //http response kodu 200 ise response text'i değişkene ekliyoruz
  }
  Serial.println(httpCode); // Seriale yazılıyor
  Serial.println(payload); // Seriale yazılıyor
  http.end(); // Bağlantı sonlandırılıyor
  return payload; // Veri geri gönderiliyor
}


// Seri numarasını yazdıran method
void printSerialNum(String seriNum)
{
  lcd.clear(); // LCD temizleniyor
  lcd.print("Okunan Kart : "); // LCD ye yazılıyor
  lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
  lcd.print(seriNum); // LCD ye yazılıyor
  Serial.print("Okunan Kart : "); // Seriale yazılıyor
  Serial.println(seriNum); // Seriale yazılıyor
  delay(1000); // 1 sn bekleniyor
}


// Pin modlarını ayarlayan method
void initPinModes()
{
  Serial.begin(115200); // Serial 115200 bps ile başlatılıyor
  delay(100); // 0.1 sn bekleniyor
  Wire.begin(D2, D1); // LCD için I2C başlatılıyor
  pinMode(BUZZER_PIN, OUTPUT); // Buzzer pini OUTPUT olarak ayarlanıyor
  pinMode(ROLE_PIN, OUTPUT); // Röle pini OUTPUT olarak ayarlanıyor
}


// LCD başlatma methodu
void initLCD()
{
  lcd.begin(); // LCD başlatılıyor
  lcd.home(); // LCD cursoru ilk pozisyona getiriliyor
}


// RfId başlatma methodu
void initRFID()
{
  SPI.begin(); // SPI başlatılıyor
  rfid.PCD_Init(); // RfId başlatılıyor
}


// LCD ye ana ekran mesajı yazdıran methodu
void lcdClearAnaEkran()
{
  lcd.clear(); // LCD temizleniyor
  lcd.print("Yonetim Bilisim"); // LCD ye yazılıyor.
  lcd.setCursor(0, 1); // LCD alt satıra geçiliyor
  lcd.print("   Sistemleri"); // LCD ye yazılıyor.
}

String getValue(String data, char separator, int index)
{
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length()-1;

  for(int i=0; i<=maxIndex && found<=index; i++){
    if(data.charAt(i)==separator || i==maxIndex){
        found++;
        strIndex[0] = strIndex[1]+1;
        strIndex[1] = (i == maxIndex) ? i+1 : i;
    }
  }

  return found>index ? data.substring(strIndex[0], strIndex[1]) : "";
}
``` 

# Sql Prosedürü
```
CREATE DEFINER=`discovery_kgs`@`%` PROCEDURE `CheckCard`(IN `crd` varchar(40),IN `rou` int)
BEGIN
DECLARE rtr INTEGER;
DECLARE antiPass VARCHAR(50);
DECLARE lastRoute INTEGER;
DECLARE logCount INTEGER;
DECLARE n VARCHAR(200);
DECLARE lastDate TIMESTAMP;
DECLARE suAn TIMESTAMP;
DECLARE fark TIME;

SET suAn = (SELECT NOW());

SELECT COUNT(*) INTO rtr FROM Cards WHERE CardId = crd AND Active = 1;

IF rtr > 0 THEN
SELECT CONCAT(`Name`,' ',`Surname`) INTO n FROM Cards WHERE CardId = crd;

SELECT `Value` INTO antiPass FROM Settings WHERE Item = 'AntiPass';
IF AntiPass = '1' THEN
SET lastRoute = (SELECT `Route` FROM `Logs` WHERE CardId = crd AND `Status` = 1 ORDER BY Id DESC LIMIT 1);
SET logCount = (SELECT COUNT(*) FROM `Logs` WHERE CardId = crd AND `Status` = 1 ORDER BY Id DESC LIMIT 1);
IF logCount = 0 THEN
INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
SELECT n AS `Name`;
ELSEIF rou = lastRoute THEN
INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (CONCAT(n,' - AntiPass'), crd, suAn, rou, 0);
SELECT '0' AS `Name`;
ELSE
IF rou = '1' THEN
SET lastDate = (SELECT Date FROM `Logs` WHERE CardId = crd AND `Status` = 1 AND Route = 0 ORDER BY Id DESC LIMIT 1);
SET fark = SEC_TO_TIME(UNIX_TIMESTAMP(suAn) - UNIX_TIMESTAMP(lastDate));
INSERT INTO Logs (`Name`, CardId, Date, Sure, Route, `Status`) VALUES (n, crd, suAn, fark, rou, rtr);
SELECT CONCAT(n,'|',fark) AS `Name`;
ELSE
INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
SELECT n AS `Name`;
END IF;

END IF;
ELSE
INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
SELECT n AS `Name`;
END IF;
ELSE
INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES ('Tanımsız Kart', crd, suAn, rou, rtr);
SELECT '0' AS `Name`;
END IF;
END
```
