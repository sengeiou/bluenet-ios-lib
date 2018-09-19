//
//  DfuHandler.swift
//  BluenetLibIOS
//
//  Created by Alex de Mulder on 10/08/16.
//  Copyright © 2016 Alex de Mulder. All rights reserved.
//

import Foundation
import PromiseKit
import CoreBluetooth


public class DeviceHandler {
    let bleManager : BleManager!
    var settings : BluenetSettings!
    let eventBus : EventBus!
    var deviceList : [String: AvailableDevice]!
    
    
    init (bleManager:BleManager, eventBus: EventBus, settings: BluenetSettings, deviceList: [String: AvailableDevice]) {
        self.bleManager = bleManager
        self.settings   = settings
        self.eventBus   = eventBus
        self.deviceList = deviceList
        
    }
    
    public func getFirmwareRevision() -> Promise<String> {
        return getSoftwareRevision()
    }
    
    
    /**
     * Returns a symvar version number like  "1.1.0"
     */
    public func getSoftwareRevision() -> Promise<String> {
        return self.bleManager.readCharacteristicWithoutEncryption(CSServices.DeviceInformation, characteristic: DeviceCharacteristics.FirmwareRevision)
            .then{ data -> Promise<String> in
                return Promise<String>{fulfill, reject in fulfill(Conversion.uint8_array_to_string(data))
            }}
    }
    
    /**
     * Returns a hardware version:
     *  hardwareVersion + productionRun + housingId + reserved + nordicChipVersion
     *
     *  hardwareVersion:
     *  ----------------------
     *  | GENERAL | PCB      |
     *  | PRODUCT | VERSION  |
     *  | INFO    |          |
     *  ----------------------
     *  | 1 01 02 | 00 92 00 |
     *  ----------------------
     *  |  |  |    |  |  |---  Patch number of PCB version
     *  |  |  |    |  |------  Minor number of PCB version
     *  |  |  |    |---------  Major number of PCB version
     *  |  |  |--------------  Product Type: 1 Dev, 2 Plug, 3 Builtin, 4 Guidestone
     *  |  |-----------------  Market: 1 EU, 2 US
     *  |--------------------  Family: 1 Crownstone
     *
     * productionRun = "0000"         (4)
     * housingId = "0000"             (4)
     * reserved = "00000000"          (8)
     * nordicChipVersion = "xxxxxx"   (6)
     */
    public func getHardwareRevision() -> Promise<String> {
        return self.bleManager.readCharacteristicWithoutEncryption(CSServices.DeviceInformation, characteristic: DeviceCharacteristics.HardwareRevision)
            .then{ data -> Promise<String> in
                return Promise<String>{fulfill, reject in fulfill(Conversion.uint8_array_to_string(data))
            }}
    }
    
    
    
    public func getBootloaderRevision() -> Promise<String> {
        return self.bleManager.getServicesFromDevice()
            .then{ services in
                var isInDfuMode = false
                for service in services {
                    if service.uuid.uuidString == DFUServiceUUID {
                        isInDfuMode = true
                        break
                    }
                }
                
                if (isInDfuMode == false) {
                    throw BleError.NOT_IN_DFU_MODE
                }
                
                return self.getSoftwareRevision()
            }
    }

    
}
