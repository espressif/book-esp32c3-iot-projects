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
//  SceneSelectDevicesVC.swift
//  ESPRainMaker
//

import UIKit

class SceneSelectDevicesVC: UIViewController, SelectDeviceActionCellDelegate {
    
    static func getVC() -> SceneSelectDevicesVC {
        let storyboard = UIStoryboard(name: "Scene", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: SceneSelectDevicesVC.storyboardId) as! SceneSelectDevicesVC
        return vc
    }
    
    static let storyboardId = "SceneSelectDevicesVC"
    var availableDeviceCopy: [Device]!
    var selectedIndexPath: [IndexPath] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register cells for tableview
        self.registerCells(tableView)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        ESPSceneManager.shared.configureDeviceForCurrentScene()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension SceneSelectDevicesVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 60.5
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 25.0
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if availableDeviceCopy[section].collapsed {
            return 0
        }
        return availableDeviceCopy[section].params?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getTableViewCellBasedOn(tableView: tableView, availableDeviceCopy: availableDeviceCopy, serviceType: .scene, scheduleDelegate: self, indexPath: indexPath)
        cell.borderWidth = 0.5
        cell.borderColor = .lightGray
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "deviceHV") as! DeviceHeaderView
        let device = availableDeviceCopy[section]
        headerView.cellType = .scene
        headerView.deviceLabel.text = device.deviceName
        headerView.section = section
        headerView.device = device
        headerView.delegate = self
        headerView.deviceStatusLabel.text = device.sceneAction.description
        if device.collapsed {
            headerView.arrowImageView.image = UIImage(named: "right_arrow")
        } else {
            headerView.arrowImageView.image = UIImage(named: "down_arrow")
        }
        if device.selectedParams == 0 {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
        } else if device.selectedParams == device.params?.count {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_select"), for: .normal)
        } else {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_partial"), for: .normal)
        }
        return headerView
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    func numberOfSections(in _: UITableView) -> Int {
        return availableDeviceCopy.count
    }
}

extension SceneSelectDevicesVC: ScheduleActionDelegate {
    func takeScheduleNotAllowedAction(action _: ScheduleActionStatus) {}

    func headerViewDidTappedFor(section: Int) {
        availableDeviceCopy[section].collapsed = !availableDeviceCopy[section].collapsed
        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
    }

    func paramStateChangedat(indexPath: IndexPath) {
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }

    func expandSection(expand: Bool, section: Int) {
        availableDeviceCopy[section].collapsed = !expand
        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
    }
}
