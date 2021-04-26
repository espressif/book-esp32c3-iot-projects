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
//  DeviceTraitListViewController.swift
//  ESPRainMaker
//

import Alamofire
import FlexColorPicker
import MBProgressHUD
import UIKit

class DeviceTraitListViewController: UIViewController {
    
    // Constant keys
    let timeSeriesProperty = "time_series"
    
    var device: Device!
    var pollingTimer: Timer!
    var skipNextAttributeUpdate = false

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var offlineLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!

    var dataSource: [Param] = []
    var foundCentralParam = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "StaticControlTableViewCell", bundle: nil), forCellReuseIdentifier: "staticControlTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        tableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")
        tableView.register(UINib(nibName: "CentralSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "centralSwitchTVC")
        tableView.register(UINib(nibName: "RoundHueSliderTableViewCell", bundle: nil), forCellReuseIdentifier: "roundHueSliderTVC")
        tableView.register(UINib(nibName: String(describing: TriggerTableViewCell.self), bundle: nil), forCellReuseIdentifier: TriggerTableViewCell.reuseIdentifier)
        tableView.register(ParamSwitchTableViewCell.self, forCellReuseIdentifier: "switchParamTableViewCell")

        titleLabel.text = device?.getDeviceName() ?? "Details"
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableView.automaticDimension
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.contentInset = insets

        if device?.isReachable() ?? false {
            if ESPNetworkMonitor.shared.isConnectedToWifi || ESPNetworkMonitor.shared.isConnectedToNetwork {
                showLoader(message: "Getting info")
                updateDeviceAttributes()
            }
        } else {
            checkForCentralParam()
        }
        checkOfflineStatus()
    }

    // Method to show central param based on UI type
    private func checkForCentralParam() {
        dataSource.removeAll()
        foundCentralParam = false
        // Check if UI type is of hue circle. Verify if bounds are in valid region.
        for param in device?.params ?? [] {
            if param.uiType == Constants.hueCircle, let bounds = param.bounds, bounds["min"] as? Int ?? 0 == 0, bounds["max"] as? Int ?? 360 == 360 {
                dataSource.insert(param, at: 0)
                foundCentralParam = true
                continue
            }
            dataSource.append(param)
        }
        if !foundCentralParam {
            dataSource = []
            for param in device?.params ?? [] {
                // Check if UI type is of big Switch.
                if param.uiType == Constants.bigSwitch, param.dataType?.lowercased() == "bool" {
                    foundCentralParam = true
                    dataSource.insert(param, at: 0)
                } else {
                    dataSource.append(param)
                }
            }
        }
        // Remove hidden UI type parameters from list.
        dataSource = dataSource.filter({ $0.uiType != Constants.hidden })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNetworkUpdate()
        tabBarController?.tabBar.isHidden = true
        pollingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paramUpdated), name: Notification.Name(Constants.paramUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkOfflineStatus), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadParamTableView), name: Notification.Name(Constants.reloadParamTableView), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollingTimer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func reloadParamTableView() {
        tableView.reloadData()
    }

    @objc func appEnterForeground() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
    }

    @objc func appEnterBackground() {
        pollingTimer.invalidate()
    }

    @objc func fetchNodeInfo() {
        if skipNextAttributeUpdate {
            skipNextAttributeUpdate = false
        } else {
            refreshDeviceAttributes()
        }
    }

    @objc func paramUpdated() {
        skipNextAttributeUpdate = true
    }

    @objc func checkNetworkUpdate() {
        DispatchQueue.main.async {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.networkIndicator.isHidden = true
            } else {
                self.networkIndicator.isHidden = false
            }
        }
    }

    func refreshDeviceAttributes() {
        if device?.isReachable() ?? false {
            NetworkManager.shared.getDeviceParam(device: device) { error in
                if error != nil {
                    return
                }
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.tableView.reloadData()
                }
            }
        }
    }

    func updateDeviceAttributes() {
        NetworkManager.shared.getNodeInfo(nodeId: (device?.node?.node_id)!) { node, error in
            if error != nil {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error!!",
                                                            message: error?.description,
                                                            preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        Utility.hideLoader(view: self.view)
                    }
                    alertController.addAction(retryAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                if let index = User.shared.associatedNodeList?.firstIndex(where: { node -> Bool in
                    node.node_id == (self.device?.node?.node_id)!
                }) {
                    let oldNode = User.shared.associatedNodeList![index]
                    node?.localNetwork = oldNode.localNetwork
                    User.shared.associatedNodeList![index] = node!
                    if let currentDevice = node!.devices?.first(where: { nodeDevice -> Bool in
                        nodeDevice.name == self.device?.name
                    }) {
                        self.device = currentDevice
                    }
                }
            }
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.checkForCentralParam()
                self.tableView.reloadData()
            }
        }
    }

    @objc func checkOfflineStatus() {
        if device?.node?.localNetwork ?? false {
            if device.node?.supportsEncryption ?? false {
                offlineLabel.text = "🔒 Reachable on WLAN"
            } else {
                offlineLabel.text = "Reachable on WLAN"
            }
            offlineLabel.isHidden = false
        } else if device?.node?.isConnected ?? true {
            offlineLabel.isHidden = true
        } else {
            offlineLabel.text = device?.node?.nodeStatus ?? ""
            offlineLabel.isHidden = false
        }
    }

    func showLoader(message: String) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.backgroundView.blurEffectStyle = .dark
            loader.bezelView.backgroundColor = UIColor.white
        }
    }

    // MARK: - IB Actions

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func infoButtonPressed(_: Any) {
        // Get current node by node ID
        if let i = User.shared.associatedNodeList!.firstIndex(where: { $0.node_id == self.device?.node?.node_id }) {
            let currentNode = User.shared.associatedNodeList![i]
            goToNodeDetails(node: currentNode)
        }
    }

    func goToNodeDetails(node: Node) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
        destination.currentNode = node
        navigationController?.pushViewController(destination, animated: true)
    }

    func getTableViewGenericCell(attribute: Param, indexPath: IndexPath) -> GenericControlTableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        object_setClass(genericCell, GenericParamTableViewCell.self)
        let cell = genericCell as! GenericParamTableViewCell
        cell.controlName.text = attribute.name
        cell.paramDelegate = self
        if let value = attribute.value {
            cell.controlValue = "\(value)"
        }
        cell.controlValueLabel.text = cell.controlValue
        if attribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
            cell.editButton.isHidden = false
        } else {
            cell.editButton.isHidden = true
        }
        
        if attribute.properties?.contains(timeSeriesProperty) ?? false {
            cell.tapButton.isHidden = false
        } else {
            cell.tapButton.isHidden = true
        }
        
        if let data_type = attribute.dataType {
            cell.dataType = data_type
        }
        cell.device = device
        cell.param = attribute
        if let attributeName = attribute.name {
            cell.attributeKey = attributeName
        }
        return cell
    }

    func getTableViewCellOfCentralParam(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == Constants.hueCircle {
            let cell = tableView.dequeueReusableCell(withIdentifier: "roundHueSliderTVC", for: indexPath) as! RoundHueSliderTableViewCell
            cell.device = device
            cell.param = dynamicAttribute
            cell.paramDelegate = self
            let currentColor = HSBColor(hue: CGFloat(dynamicAttribute.value as! Int) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)

            cell.hueSlider.setSelectedHSBColor(currentColor, isInteractive: true)
            cell.selectedColor.setSelectedHSBColor(currentColor, isInteractive: true)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "centralSwitchTVC", for: indexPath) as! CentralSwitchTableViewCell
        cell.device = device
        cell.param = dynamicAttribute
        cell.paramDelegate = self
        let switchState = dynamicAttribute.value as? Bool ?? false
        if switchState {
            cell.powerButton.setBackgroundImage(UIImage(named: "central_switch_on"), for: .normal)
        } else {
            cell.powerButton.setBackgroundImage(UIImage(named: "central_switch_off"), for: .normal)
        }
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == Constants.slider {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                if let bounds = dynamicAttribute.bounds {
                    let maxValue = bounds["max"] as? Float ?? 100
                    let minValue = bounds["min"] as? Float ?? 0
                    if minValue < maxValue {
                        let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
                        object_setClass(sliderCell, ParamSliderTableViewCell.self)
                        let cell = sliderCell as! ParamSliderTableViewCell

                        cell.paramDelegate = self
                        cell.hueSlider.isHidden = true
                        cell.slider.isHidden = false
                        cell.param = dynamicAttribute
                        if let bounds = dynamicAttribute.bounds {
                            cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                            cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                        }
                        if dynamicAttribute.dataType!.lowercased() == "int" {
                            let value = Int(dynamicAttribute.value as? Float ?? 100)
                            cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                            cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                            cell.slider.value = Float(value)
                        } else {
                            cell.minLabel.text = "\(cell.slider.minimumValue)"
                            cell.maxLabel.text = "\(cell.slider.maximumValue)"
                            cell.slider.value = dynamicAttribute.value as? Float ?? 100
                        }
                        cell.device = device
                        cell.dataType = dynamicAttribute.dataType
                        if let attributeName = dynamicAttribute.name {
                            cell.paramName = attributeName
                        }
                        if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                            cell.slider.isEnabled = true
                        } else {
                            cell.slider.isEnabled = false
                        }
                        cell.title.text = dynamicAttribute.name ?? ""
                        setIconsForSliderCell(cell: cell, param: dynamicAttribute)
                        return cell
                    }
                }
            }
        } else if dynamicAttribute.uiType == Constants.toggle || dynamicAttribute.uiType == Constants.bigSwitch, dynamicAttribute.dataType?.lowercased() == "bool" {
            let switchCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            object_setClass(switchCell, ParamSwitchTableViewCell.self)
            let cell = switchCell as! ParamSwitchTableViewCell
            cell.paramDelegate = self
            cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
            cell.device = device
            cell.param = dynamicAttribute
            if let attributeName = dynamicAttribute.name {
                cell.attributeKey = attributeName
            }
            if let switchState = dynamicAttribute.value as? Bool {
                if switchState {
                    cell.controlStateLabel.text = "On"
                } else {
                    cell.controlStateLabel.text = "Off"
                }
                cell.toggleSwitch.setOn(switchState, animated: true)
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                cell.toggleSwitch.isEnabled = true
            } else {
                cell.toggleSwitch.isEnabled = false
            }
            return cell
        } else if dynamicAttribute.uiType == Constants.hue || dynamicAttribute.uiType == Constants.hueCircle {
            var minValue = 0
            var maxValue = 360
            if let bounds = dynamicAttribute.bounds {
                minValue = bounds["min"] as? Int ?? 0
                maxValue = bounds["max"] as? Int ?? 360
            }

            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
            object_setClass(sliderCell, ParamSliderTableViewCell.self)
            let cell = sliderCell as! ParamSliderTableViewCell
            cell.paramDelegate = self
            cell.param = dynamicAttribute
            cell.slider.isHidden = true
            cell.hueSlider.isHidden = false

            cell.hueSlider.minimumValue = CGFloat(minValue)
            cell.hueSlider.maximumValue = CGFloat(maxValue)

            if minValue == 0 && maxValue == 360 {
                cell.hueSlider.hasRainbow = true
                cell.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
            } else {
                cell.hueSlider.hasRainbow = false
                cell.hueSlider.minColor = UIColor(hue: CGFloat(minValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.hueSlider.maxColor = UIColor(hue: CGFloat(maxValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }

            let value = CGFloat(dynamicAttribute.value as? Int ?? 0)
            cell.hueSlider.value = CGFloat(value)
            cell.minLabel.text = "\(minValue)"
            cell.maxLabel.text = "\(maxValue)"
            cell.hueSlider.thumbColor = UIColor(hue: value / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            cell.device = device
            cell.dataType = dynamicAttribute.dataType
            if let attributeName = dynamicAttribute.name {
                cell.paramName = attributeName
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                cell.hueSlider.isEnabled = true
            } else {
                cell.hueSlider.isEnabled = false
            }
            cell.title.text = dynamicAttribute.name ?? ""

            return cell
        } else if dynamicAttribute.uiType == Constants.dropdown {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "string" {
                let dropDownCell = tableView.dequeueReusableCell(withIdentifier: "dropDownTableViewCell", for: indexPath) as! DropDownTableViewCell
                object_setClass(dropDownCell, ParamDropDownTableViewCell.self)
                let cell = dropDownCell as! ParamDropDownTableViewCell
                cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
                cell.device = device
                cell.param = dynamicAttribute
                cell.paramDelegate = self

                var currentValue = ""
                if dataType == "string" {
                    currentValue = dynamicAttribute.value as! String
                } else {
                    currentValue = String(dynamicAttribute.value as! Int)
                }
                cell.controlValueLabel.text = currentValue
                cell.currentValue = currentValue

                var datasource: [String] = []
                if dataType == "int" {
                    guard let bounds = dynamicAttribute.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int, let step = bounds["step"] as? Int, max > min else {
                        return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                    }
                    for item in stride(from: min, to: max + 1, by: step) {
                        datasource.append(String(item))
                    }
                } else if dynamicAttribute.dataType?.lowercased() == "string" {
                    datasource.append(contentsOf: dynamicAttribute.valid_strs ?? [])
                }
                cell.datasource = datasource

                if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
                    cell.dropDownButton.isHidden = false
                } else {
                    cell.dropDownButton.isHidden = true
                }

                if !cell.datasource.contains(currentValue) {
                    cell.controlValueLabel.text = currentValue + " (Invalid)"
                }
                return cell
            }
        } else if dynamicAttribute.uiType == Constants.trigger, let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "bool" {
            let triggerCell = tableView.dequeueReusableCell(withIdentifier: "triggerTVC", for: indexPath) as! TriggerTableViewCell
            object_setClass(triggerCell, ParamTriggerTableViewCell.self)
            let cell = triggerCell as! ParamTriggerTableViewCell
            cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
            cell.device = device
            cell.param = dynamicAttribute
            cell.paramDelegate = self
            if let attributeName = dynamicAttribute.name {
                cell.paramName = attributeName
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                cell.triggerButton.isEnabled = true
                cell.triggerButton.alpha = 1.0
            } else {
                cell.triggerButton.isEnabled = false
                cell.triggerButton.alpha = 0.5
            }
            return cell
        }

        return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
    }

    private func setIconsForSliderCell(cell: ParamSliderTableViewCell, param: Param) {
        if param.type?.lowercased() == Constants.deviceBrightnessParam {
            cell.minImage.image = UIImage(named: "brightness_low")
            cell.maxImage.image = UIImage(named: "brightness_high")
        } else if param.type?.lowercased() == Constants.deviceSaturationParam {
            cell.minImage.image = UIImage(named: "saturation_low")
            cell.maxImage.image = UIImage(named: "saturation_high")
        } else if param.type?.lowercased() == Constants.deviceCCTParam {
            cell.minImage.image = UIImage(named: "cct_low")
            cell.maxImage.image = UIImage(named: "cct_high")
        } else {
            cell.maxImage.image = nil
            cell.minImage.image = nil
        }
    }
}

extension DeviceTraitListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 40.0
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = SectionHeaderView.instanceFromNib()
        if section >= dataSource.count {
            let staticControl = device?.attributes![section - dataSource.count]
            sectionHeaderView.sectionTitle.text = staticControl?.name!.deletingPrefix(device!.name!)
        } else {
            let control = dataSource[section]
            sectionHeaderView.sectionTitle.text = control.name!.deletingPrefix(device!.name!)
        }
        return sectionHeaderView
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if foundCentralParam {
            if indexPath.section == 0 {
                return 300.0
            }
        }
        return UITableView.automaticDimension
    }
}

extension DeviceTraitListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (dataSource.count) + (device?.attributes?.count ?? 0)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var paramCell: UITableViewCell!
        if indexPath.section == 0, foundCentralParam {
            return getTableViewCellOfCentralParam(dynamicAttribute: dataSource[indexPath.section], indexPath: indexPath)
        }
        if indexPath.section >= dataSource.count {
            let staticControl = device?.attributes![indexPath.section - dataSource.count]
            let cell = tableView.dequeueReusableCell(withIdentifier: "staticControlTableViewCell", for: indexPath) as! StaticControlTableViewCell
            cell.controlNameLabel.text = staticControl?.name ?? ""
            cell.controlValueLabel.text = staticControl?.value as? String ?? ""
            paramCell = cell as UITableViewCell
        } else {
            let control = dataSource[indexPath.section]
            paramCell = getTableViewCellBasedOn(dynamicAttribute: control, indexPath: indexPath)
        }
        paramCell.isUserInteractionEnabled = true
        return paramCell
    }
}

extension DeviceTraitListViewController: ParamUpdateProtocol {
    func failureInUpdatingParam() {
        DispatchQueue.main.async {
            Utility.showToastMessage(view: self.view, message: "Fail to update parameter. Please check you network connection!!")
        }
    }
}

class SectionHeaderView: UIView {
    @IBOutlet var sectionTitle: UILabel!

    class func instanceFromNib() -> SectionHeaderView {
        return UINib(nibName: "ControlSectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SectionHeaderView
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count + 1))
    }
}
