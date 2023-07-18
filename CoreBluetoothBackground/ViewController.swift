import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var connectPeripheral: CBPeripheral!
    
    let audioSession = AVAudioSession.sharedInstance()
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var connectedDeivce: UILabel!
    @IBOutlet weak var conectionStatus: UILabel!
    @IBOutlet weak var batterLevelLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
//    let batteryLevelChracteristicCBUUID = CBUUID(string: "0x2A19")
    let temperatureAndHumidityUUID = CBUUID(string: "EBE0CCC1-7A0A-4B0C-8A1A-6FF2997DA3A6")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central status is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        case .poweredOff:
            print("Central status is .poweredOff")
        case .unauthorized:
            print("Central status is .unauthorized")
        case .unknown:
            print("Central status is .unknown")
        case .resetting:
            print("Central status is .resetting")
        case .unsupported:
            print("Central status is .unsupported")
        @unknown default:
            fatalError("What happend?")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name != nil {
            print(peripheral)
        }
        
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        
        if peripheral.name == "LYWSD03MMC" {
            central.connect(connectPeripheral)
            conectionStatus.text = "connect"
            central.stopScan()
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let stringWithoutWhitespace = peripheral.name?.replacingOccurrences(of: "       ", with: "")
        connectedDeivce.text = "\(stringWithoutWhitespace ?? "unknown Device")"
        connectPeripheral.discoverServices(nil)
    }
    
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("ERROR discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found")
            return
        }
        
        for service in services {
//            print("Discovered service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
//                print("\(characteristic.uuid): properties contains .read")
            }
            
            if characteristic.properties.contains(.notify) {
                
                if characteristic.uuid == temperatureAndHumidityUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                }
                
//                print("\(characteristic.uuid): properties contains .notify")
            }
            
        }
    }
    
//    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//        if let error = error {
//            print("Error changing notification state: \(error.localizedDescription)")
//            return
//        }
//
//        if characteristic.isNotifying {
//            print("Notifications enabled for characteristic: \(characteristic.uuid)")
//        } else {
//            print("Notifications disabled for characteristic: \(characteristic.uuid)")
//        }
//    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
            
        case temperatureAndHumidityUUID:
            guard let value = characteristic.value else { return }
            let byteArray = [UInt8](value)
//            print(byteArray)  // [140, 10, 56, 43, 11] [온도, ?, 습도, ?, ?]
                
            let temperatureData: Float = value.withUnsafeBytes { rawBufferPointer in
                let buffer = rawBufferPointer.bindMemory(to: Int16.self).baseAddress!
                let integerValue = Int16(littleEndian: buffer.pointee)
                let floatValue = Float(integerValue) / 100.0
                return floatValue
            }
            DispatchQueue.main.async {
                self.temperatureLabel.text = "\(temperatureData)°C"
                self.humidityLabel.text = "\(byteArray[2])%"
                self.sendToServer(String(temperatureData), String(byteArray[2]))
//                if temperatureData > 26 {
//                    self.playSiren()
//                } else {
//                    self.stopSiren()
//                }
            }
        
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
        
    }
    
    func sendToServer(_ temp: String, _ humi: String) {
        guard let url = URL(string: "https://wkwebview.run.goorm.site/backgroundPush.php") else {
            print("Invaild URL")
            return
        }
        
        let parameters = ["temperature": temp, "humidity": humi]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to serialize data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        }
        task.resume()
    }
    
    func playSiren() {
        
        do {
            try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        guard let path = Bundle.main.path(forResource: "siren2", ofType: "mp3") else {
            print("Failed to find the siren.mp3 file")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play the siren sound: \(error.localizedDescription)")
        }
    }
    
    func stopSiren() {
        audioPlayer?.stop()
    }
}
