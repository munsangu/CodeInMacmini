/*
 
 Temperature Measurement Service
 Characteristic: Temperature Measurement Characteristic
 UUID: EBE0CCC1-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 온도 값을 읽는 특성
 
 Humidity Measurement Service
 Characteristic: Humidity Measurement Characteristic
 UUID: EBE0CCC4-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 습도 값을 읽는 특성
 
 Device Information Service
 Characteristic: Device Name Characteristic
 UUID: EBE0CCBC-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 장치 이름을 읽는 특성
 
 Characteristic: Device Manufacturer Characteristic
 UUID: EBE0CCB7-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 장치 제조사를 읽는 특성
 
 Characteristic: Device Model Characteristic
 UUID: EBE0CCB9-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 장치 모델을 읽는 특성
 
 Characteristic: Device Serial Number Characteristic
 UUID: EBE0CCBA-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 장치 일련 번호를 읽는 특성
 
 Characteristic: Firmware Revision Characteristic
 UUID: EBE0CCBB-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 펌웨어 버전을 읽는 특성
 
 Battery Level Service
 Characteristic: Battery Level Characteristic
 UUID: EBE0CCBE-7A0A-4B0C-8A1A-6FF2997DA3A6
 Description: 배터리 레벨을 읽는 특성
 
 */

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var connectPeripheral: CBPeripheral!
    
    @IBOutlet weak var connectedDeivce: UILabel!
    @IBOutlet weak var conectionStatus: UILabel!
    @IBOutlet weak var batterLevelLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    let batteryLevelChracteristicCBUUID = CBUUID(string: "0x2A19")
    let temperatureUUID = CBUUID(string: "EBE0CCC1-7A0A-4B0C-8A1A-6FF2997DA3A6")
    let humidityUUID = CBUUID(string: "EBE0CCBC-7A0A-4B0C-8A1A-6FF2997DA3A6")
    
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
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("central: \(central)")
        print("dict: \(dict)")
    }
    
}

extension ViewController: CBPeripheralDelegate {
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                print("\(characteristic.uuid): properties contains .read")
            }
            
            if characteristic.properties.contains(.notify) {
                
                if characteristic.uuid == temperatureUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                }
                
                if characteristic.uuid == humidityUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                    
                }
                                
                print("\(characteristic.uuid): properties contains .notify")
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications enabled for characteristic: \(characteristic.uuid)")
        } else {
            print("Notifications disabled for characteristic: \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
            
        case temperatureUUID:
            guard let value = characteristic.value else { return }
            let temperatureData: Float = value.withUnsafeBytes { rawBufferPointer in
                let buffer = rawBufferPointer.bindMemory(to: Int16.self).baseAddress!
                let integerValue = Int16(littleEndian: buffer.pointee)
                let floatValue = Float(integerValue) / 100.0
                return floatValue
            }
            DispatchQueue.main.async {
                self.temperatureLabel.text = "\(temperatureData)°C"
                self.sendToServer(String(temperatureData))
//                print("Temp: \(String(temperatureData))°C")
            }
            
        case batteryLevelChracteristicCBUUID:
            guard let characteristicData = characteristic.value, let byte = characteristicData.first else { return }
            DispatchQueue.main.async {
                self.batterLevelLabel.text = "\(String(byte))%"
//                print("Battery: \(String(byte))%")
            }
            
        case humidityUUID:
            guard let characteristicData = characteristic.value else { return }
            
            if characteristicData.count >= 2 {
                let humidityData = characteristicData.withUnsafeBytes { rawBufferPointer in
                    let buffer = rawBufferPointer.bindMemory(to: Int16.self).baseAddress!
                    return buffer.pointee
                }
                
                let humidityPercentage = Float(humidityData)
                DispatchQueue.main.async {
                    self.humidityLabel.text = "\(humidityPercentage)%"
                }
            }
            
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
        
    }
    
    func sendToServer(_ temp: String) {
        guard let url = URL(string: "https://wkwebview.run.goorm.site/backgroundPush.php") else {
            print("Invaild URL")
            return
        }
        
        let parameters = ["value": temp]
        
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
    
}
