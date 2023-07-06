// MARK: 기록 사항
// 1. 1개월간의 DB들 자체 저장 -> 전송 -> 삭제
// 2. Background Mode에서도 블루투스 연결 지속되야 함 -> 지속 가능 
// (3. Background Mode에서 서버와 통신하는 등의 작업은 30초 이내로 해결해야함)
// 4. Background Mode에서도 데이터가 지속적으로 들어와야 함 (Background processing Option)

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var connectPeripheral: CBPeripheral!
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var connectionTimer: Timer?
    var backgroundTaskExpiration: DispatchTime?
    
    @IBOutlet weak var connectedDeivce: UILabel!
    @IBOutlet weak var conectionStatus: UILabel!
    @IBOutlet weak var batterLevelLabel: UILabel!
    @IBOutlet weak var pnpIDLabel: UILabel!
    
    let batteryLevelChracteristicCBUUID = CBUUID(string: "0x2A19")
    let pnpIDChracteristicCBUUID = CBUUID(string: "0x2A50")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
//    func receiveRandomNumber() {
//        // Set the URL of the PHP script
//        let url = URL(string: "https://wkwebview.run.goorm.site/randomNumber.php")
//
//        // Create a URL session
//        let session = URLSession.shared
//
//        // Create a data task for the URL session
//        let task = session.dataTask(with: url!) { (data, response, error) in
//            if let error = error {
//                print("Error: \(error)")
//                return
//            }
//
//            // Check if data was received
//            guard let data = data else {
//                print("No data received")
//                return
//            }
//
//            do {
//                // Parse the JSON data
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    // Handle the received data
//                    let value1 = json["value1"] as? Int
//                    let value2 = json["value2"] as? Int
//
//                    // Do something with the values
//                    print("Value 1: \(value1 ?? 0)")
//                    print("Value 2: \(value2 ?? 0)")
//                }
//            } catch {
//                print("Error parsing JSON: \(error)")
//            }
//        }
//
//        // Start the data task
//        task.resume()
//    }
    
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
        
//        if peripheral.name == "Smart Tank 510 series" {
//            central.connect(connectPeripheral)
//            conectionStatus.text = "connect"
//            central.stopScan()
//        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let stringWithoutWhitespace = peripheral.name?.replacingOccurrences(of: "       ", with: "")
        connectedDeivce.text = "\(stringWithoutWhitespace ?? "unknown Device")"
        connectPeripheral.discoverServices(nil)
        
//        beginBackgroundTask()
    }
    
//    func checkBackgroundTaskExpiration() {
//        guard let expiration = backgroundTaskExpiration else { return }
//
//        if DispatchTime.now() > expiration {
//            self.endBackgroundTask()
//        }
//    }
//
//    func beginBackgroundTask() {
//        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "BackgroudTask") {
//            self.endBackgroundTaskIfNeed()
//        }
//
//        backgroundTaskExpiration = DispatchTime.now() + .seconds(30)
//
//        DispatchQueue.main.async {
//            self.connectionTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.checkConnectionStatus), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.connectionTimer!, forMode: .default)
//            self.checkBackgroundTaskExpiration()
//        }
//    }
//
//    func endBackgroundTask() {
//        UIApplication.shared.endBackgroundTask(backgroundTask)
//        backgroundTask = .invalid
//        backgroundTaskExpiration = nil
//    }
//
//    func endBackgroundTaskIfNeed() {
//        if backgroundTask != .invalid {
//            self.endBackgroundTask()
//        }
//    }
    
    // Once a month
//    func sendTokenToServer() {
//        let url = URL(string: "https://wkwebview.run.goorm.site/backgroundPush.php")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        let postString = "value= 1"
//        request.httpBody = postString.data(using: .utf8)
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
//                print("Error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            if response.statusCode == 200 {
//                if let responseString = String(data: data, encoding: .utf8) {
//                    print("Server response: \(responseString)")
//                }
//            } else {
//                print("Error sending token: HTTP status code \(response.statusCode)")
//            }
//        }
//        task.resume()
//    }
    
//    @objc func checkConnectionStatus() {
//        if connectPeripheral.state == .connected {
//            conectionStatus.text = "connect"
//            self.sendTokenToServer()
//        } else {
//            conectionStatus.text = "disconnect"
//            connectedDeivce.text = "Nothing"
//            batterLevelLabel.text = "Nothing"
//            pnpIDLabel.text = "Nothing"
//            self.endBackgroundTaskIfNeed()
//        }
//    }
    
}

extension ViewController: CBPeripheralDelegate {
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Emmergency!!!!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chracteristics = service.characteristics else { return }
        
        for chracteristic in chracteristics {
            if chracteristic.properties.contains(.read) {
                print("\(chracteristic.uuid): properties contains .read")
                peripheral.readValue(for: chracteristic)
            } else if chracteristic.properties.contains(.notify) {
                print("\(chracteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: chracteristic)
            } else {
                print("\(chracteristic.uuid): properties not contains")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case batteryLevelChracteristicCBUUID:
            guard let characteristicData = characteristic.value, let byte = characteristicData.first else { return }
            batterLevelLabel.text = "\(String(byte))%"
        case pnpIDChracteristicCBUUID:
            guard let characteristicData = characteristic.value, let byte = characteristicData.first else { return }
            pnpIDLabel.text = "\(String(byte))"
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}
