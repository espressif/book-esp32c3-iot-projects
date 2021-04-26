// Copyright 2022 Espressif Systems
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
//  SelectDeviceActionCellDelegate.swift
//  ESPRainMaker
//

import UIKit

protocol SelectDeviceActionCellDelegate {
    func registerCells(_: UITableView)
    func getTableViewCellBasedOn(tableView: UITableView, availableDeviceCopy: [Device]?, serviceType: DeviceServiceType, scheduleDelegate: ScheduleActionDelegate?, indexPath: IndexPath) -> UITableViewCell
}

extension SelectDeviceActionCellDelegate {
    
    /// Register cells with tableview
    /// - Parameter tableView: tableview which registers cells
    func registerCells(_ tableView: UITableView) {
        tableView.register(UINib(nibName: String(describing: SwitchTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SwitchTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: GenericControlTableViewCell.self), bundle: nil), forCellReuseIdentifier: GenericControlTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: String(describing: DeviceHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: DeviceHeaderView.reuseIdentifier)
        tableView.register(UINib(nibName: String(describing: SliderTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SliderTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: DropDownTableViewCell.self), bundle: nil), forCellReuseIdentifier: DropDownTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: String(describing: TriggerTableViewCell.self), bundle: nil), forCellReuseIdentifier: TriggerTableViewCell.reuseIdentifier)
    }
    
    /// Get table view cell
    /// - Parameters:
    ///   - tableView: tableView
    ///   - availableDeviceCopy: available devices
    ///   - serviceType: device service type
    ///   - scheduleDelegate: callback
    ///   - indexPath: indexPath of cell
    /// - Returns: table view cell
    func getTableViewCellBasedOn(tableView: UITableView, availableDeviceCopy: [Device]?, serviceType: DeviceServiceType, scheduleDelegate: ScheduleActionDelegate?, indexPath: IndexPath) -> UITableViewCell {
        if let devices = availableDeviceCopy, devices.count > indexPath.section {
            let device = devices[indexPath.section]
            let param = device.params![indexPath.row]
            if param.uiType == Constants.slider {
                if let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                    if let bounds = param.bounds {
                        let maxValue = bounds["max"] as? Float ?? 100
                        let minValue = bounds["min"] as? Float ?? 0
                        if minValue < maxValue {
                            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
                            object_setClass(sliderCell, ScheduleSliderTableViewCell.self)
                            let cell = sliderCell as! ScheduleSliderTableViewCell
                            cell.cellType = serviceType
                            cell.hueSlider.isHidden = true
                            cell.slider.isHidden = false
                            if let bounds = param.bounds {
                                cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                                cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                            }
                            if param.dataType!.lowercased() == "int" {
                                let value = param.value as? Int ?? 0
                                cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                                cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                                cell.slider.value = Float(value)
                            } else {
                                cell.minLabel.text = "\(cell.slider.minimumValue)"
                                cell.maxLabel.text = "\(cell.slider.maximumValue)"
                                cell.slider.value = param.value as! Float
                            }
                            cell.param = param
                            cell.title.text = param.name ?? ""
                            if param.selected {
                                cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                                cell.slider.isEnabled = true
                                cell.slider.alpha = 1.0
                            } else {
                                cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                                cell.slider.isEnabled = false
                                cell.slider.alpha = 0.5
                            }
                            cell.device = device
                            cell.scheduleDelegate = scheduleDelegate
                            cell.indexPath = indexPath
                            return cell
                        }
                    }
                }
            } else if param.uiType == Constants.toggle, param.dataType?.lowercased() == "bool" {
                let switchCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
                object_setClass(switchCell, ScheduleSwitchTableViewCell.self)
                let cell = switchCell as! ScheduleSwitchTableViewCell
                cell.cellType = serviceType
                cell.controlName.text = param.name?.deletingPrefix(device.name!)
                cell.param = param

                if let switchState = param.value as? Bool {
                    if switchState {
                        cell.controlStateLabel.text = "On"
                    } else {
                        cell.controlStateLabel.text = "Off"
                    }
                    cell.toggleSwitch.setOn(switchState, animated: true)
                }
                cell.toggleSwitch.isEnabled = true
                if param.selected {
                    cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                    cell.toggleSwitch.isEnabled = true
                } else {
                    cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                    cell.toggleSwitch.isEnabled = false
                }
                cell.device = device
                cell.scheduleDelegate = scheduleDelegate
                cell.indexPath = indexPath
                return cell
            } else if param.uiType == Constants.hue {
                var minValue = 0
                var maxValue = 360
                if let bounds = param.bounds {
                    minValue = bounds["min"] as? Int ?? 0
                    maxValue = bounds["max"] as? Int ?? 360
                }

                let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ScheduleSliderTableViewCell.self)
                let cell = sliderCell as! ScheduleSliderTableViewCell
                cell.cellType = serviceType
                cell.scheduleDelegate = scheduleDelegate
                cell.indexPath = indexPath
                cell.slider.isHidden = true
                cell.hueSlider.isHidden = false
                cell.param = param
                cell.hueSlider.minimumValue = CGFloat(minValue)
                cell.hueSlider.maximumValue = CGFloat(maxValue)

                if minValue == 0, maxValue == 360 {
                    cell.hueSlider.hasRainbow = true
                    cell.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
                } else {
                    cell.hueSlider.hasRainbow = false
                    cell.hueSlider.minColor = UIColor(hue: CGFloat(minValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    cell.hueSlider.maxColor = UIColor(hue: CGFloat(maxValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                }

                let value = CGFloat(param.value as? Int ?? 0)
                cell.hueSlider.value = CGFloat(value)
                cell.minLabel.text = "\(minValue)"
                cell.maxLabel.text = "\(maxValue)"
                cell.hueSlider.thumbColor = UIColor(hue: value / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.device = device
                cell.title.text = param.name ?? ""

                if param.selected {
                    cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                    cell.hueSlider.isEnabled = true
                    cell.hueSlider.alpha = 1.0
                } else {
                    cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                    cell.hueSlider.isEnabled = false
                    cell.hueSlider.alpha = 0.5
                }

                return cell
            } else if param.uiType == Constants.dropdown {
                if let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "string" {
                    let dropDownCell = tableView.dequeueReusableCell(withIdentifier: "dropDownTableViewCell", for: indexPath) as! DropDownTableViewCell
                    object_setClass(dropDownCell, ScheduleDropDownTableViewCell.self)
                    let cell = dropDownCell as! ScheduleDropDownTableViewCell
                    cell.cellType = serviceType
                    cell.controlName.text = param.name?.deletingPrefix(device.name!)
                    cell.device = device
                    cell.param = param
                    cell.scheduleDelegate = scheduleDelegate
                    cell.indexPath = indexPath

                    var currentValue = ""
                    if param.dataType?.lowercased() == "string" {
                        currentValue = param.value as! String
                    } else {
                        currentValue = String(param.value as! Int)
                    }
                    cell.controlValueLabel.text = currentValue
                    cell.currentValue = currentValue
                    cell.dropDownButton.isHidden = false
                    var datasource: [String] = []
                    if dataType == "int" {
                        guard let bounds = param.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int, let step = bounds["step"] as? Int, max > min else {
                            return getTableViewGenericCell(tableView: tableView, availableDeviceCopy: availableDeviceCopy, cellType: serviceType, scheduleDelegate: scheduleDelegate, param: param, indexPath: indexPath)
                        }
                        for item in stride(from: min, to: max + 1, by: step) {
                            datasource.append(String(item))
                        }
                    } else if param.dataType?.lowercased() == "string" {
                        datasource.append(contentsOf: param.valid_strs ?? [])
                    }
                    cell.datasource = datasource

                    if param.selected {
                        cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                        cell.dropDownButton.isEnabled = true
                        cell.dropDownButton.alpha = 1.0
                    } else {
                        cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                        cell.dropDownButton.isEnabled = false
                        cell.dropDownButton.alpha = 0.5
                    }

                    if !cell.datasource.contains(currentValue) {
                        cell.controlValueLabel.text = currentValue + " (Invalid)"
                    }
                    return cell
                }
            } else if param.uiType == Constants.trigger, let dataType = param.dataType?.lowercased(), dataType == "bool" {
                let triggerCell = tableView.dequeueReusableCell(withIdentifier: "triggerTVC", for: indexPath) as! TriggerTableViewCell
                object_setClass(triggerCell, ScheduleTriggerTableViewCell.self)
                let cell = triggerCell as! ScheduleTriggerTableViewCell
                cell.controlName.text = param.name?.deletingPrefix(device.name!)
                cell.device = device
                cell.param = param
                cell.scheduleDelegate = scheduleDelegate
                cell.indexPath = indexPath
                cell.triggerButton.isUserInteractionEnabled = false
                
                if let attributeName = param.name {
                    cell.paramName = attributeName
                }
                if param.selected {
                    cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                    cell.triggerButton.alpha = 1.0
                } else {
                    cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                    cell.triggerButton.alpha = 0.5
                }
                return cell
            }
            return getTableViewGenericCell(tableView: tableView, availableDeviceCopy: availableDeviceCopy, cellType: serviceType, scheduleDelegate: scheduleDelegate, param: param, indexPath: indexPath)
        }
        return UITableViewCell()
    }

    func getTableViewGenericCell(tableView: UITableView, availableDeviceCopy: [Device]?, cellType: DeviceServiceType, scheduleDelegate: ScheduleActionDelegate?, param: Param, indexPath: IndexPath) -> ScheduleGenericTableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        object_setClass(genericCell, ScheduleGenericTableViewCell.self)
        let cell = genericCell as! ScheduleGenericTableViewCell
        cell.cellType = cellType
        if let devices = availableDeviceCopy, devices.count > indexPath.section {
            cell.device = devices[indexPath.section]
        }
        cell.scheduleDelegate = scheduleDelegate
        cell.indexPath = indexPath
        cell.controlName.text = param.name
        if let value = param.value {
            cell.controlValue = "\(value)"
            cell.controlValueLabel.text = "\(value)"
        }
        if let data_type = param.dataType {
            cell.dataType = data_type
        }
        cell.param = param
        cell.backView.backgroundColor = UIColor.white
        if param.selected {
            cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
            cell.editButton.isHidden = false
        } else {
            cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            cell.editButton.isHidden = true
        }
        return cell
    }
}
