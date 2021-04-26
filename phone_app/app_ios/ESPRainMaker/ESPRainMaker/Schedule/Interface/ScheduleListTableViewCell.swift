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
//  ScheduleListTableViewCell.swift
//  ESPRainMaker
//
import UIKit

class ScheduleListTableViewCell: UITableViewCell {
    @IBOutlet var scheduleLabel: UILabel!
    @IBOutlet var scheduleSwitch: UISwitch!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var daysLabel: UILabel!
    
    weak var delegate: ScheduleListTableViewCellDelegate?

    var index: Int!
    var schedule: ESPSchedule!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func switchStateChanged(_ sender: UISwitch) {
        ESPScheduler.shared.currentSchedule = schedule
        let currentState = ESPScheduler.shared.currentSchedule.enabled
        ESPScheduler.shared.currentSchedule.enabled = sender.isOn
        ESPScheduler.shared.currentSchedule.operation = .edit
        let view = parentViewController?.parent?.view ?? contentView
        Utility.showLoader(message: "", view: view)
        ESPScheduler.shared.shouldEnableSchedule(onView: view) { result  in
            Utility.hideLoader(view: view)
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.scheduleSwitch.isOn = !sender.isOn
                    ESPScheduler.shared.currentSchedule.enabled = currentState
                case .success(let nodesFailed):
                    self.delegate?.scheduleStateChanged(index: self.index, enabled: ESPScheduler.shared.currentSchedule.enabled, shouldRefresh: nodesFailed)
                }
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

/// Protocol to be invoked when state of schedule table view cell changes
@objc protocol ScheduleListTableViewCellDelegate {
    func scheduleStateChanged(index: Int, enabled: Bool, shouldRefresh: Bool)
}
