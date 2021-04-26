// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ESPLocalControl.swift
//  ESPRainMaker
//

import Foundation

/// Protocol to update listeners when there is change in available local services on the network.
protocol ESPLocalControlDelegate {
    func updateInAvailableLocalServices(services: [ESPLocalService])
}

/// Class to manage search and resolution of services on the local network by using Bonjour.
class ESPLocalControl: NSObject {
    var delegate: ESPLocalControlDelegate?

    private var services: [String: ESPLocalService] = [:]
    private var serviceBrowser = NetServiceBrowser()
    private var servicesBeingResolved: [NetService] = []
    private var serviceTimeout = Timer()

    let timeout: TimeInterval = 10.0

    static let shared = ESPLocalControl()

    override init() {
        super.init()
        serviceBrowser.delegate = self
    }

    /// Search for service of a particular type in a given domain.
    ///
    /// - Parameters:
    ///   - type: Service type.
    ///   - domain: Domain type.
    func searchForServicesOfType(type: String, domain: String) {
        serviceTimeout = Timer.scheduledTimer(
            timeInterval: timeout,
            target: self,
            selector: #selector(noServicesFound),
            userInfo: nil,
            repeats: false
        )

        servicesBeingResolved.removeAll()
        services.removeAll()
        serviceBrowser.stop()
        serviceBrowser.searchForServices(ofType: type, inDomain: domain)
    }

    /// Method invoked if search is taking longer than expected.
    ///
    @objc private func noServicesFound() {
        serviceBrowser.stop()
        services.removeAll()
        updateServiceList()
    }

    /// Tell delegate there is change in available services.
    ///
    private func updateServiceList() {
        delegate?.updateInAvailableLocalServices(services: Array(services.values))
    }

    /// Remove resolved service from queue of found services.
    ///
    /// - Parameters:
    ///   - service: Service that needs to be removed from the resolved queue.
    private func removeServiceFromResolveQueue(service: NetService) {
        if let serviceIndex = servicesBeingResolved.firstIndex(of: service) {
            servicesBeingResolved.remove(at: serviceIndex)
        }

        if servicesBeingResolved.count == 0 {
            updateServiceList()
        }
    }
}

extension ESPLocalControl: NetServiceBrowserDelegate {
    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        service.delegate = self
        serviceTimeout.invalidate()
        servicesBeingResolved.append(service)
        service.resolve(withTimeout: 5.0)
    }
}

extension ESPLocalControl: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        let localService = ESPLocalService(service: sender)
        localService.hostname = "\(sender.hostName ?? ""):\(sender.port)"
        services[localService.hostname] = localService
        removeServiceFromResolveQueue(service: sender)
    }

    func netService(_ sender: NetService, didNotResolve _: [String: NSNumber]) {
        removeServiceFromResolveQueue(service: sender)
    }
}
