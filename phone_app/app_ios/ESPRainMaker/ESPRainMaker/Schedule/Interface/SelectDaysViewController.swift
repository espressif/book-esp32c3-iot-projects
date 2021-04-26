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
//  SelectDaysViewController.swift
//  ESPRainMaker
//

import UIKit

class SelectDaysViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var week = ESPScheduler.shared.currentSchedule.week
    var pvc: ScheduleViewController?
    var selectAll = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if week.getDecimalConversionOfSelectedDays() == 127 {
            selectAll = true
        }
    }

    @IBAction func backButtonTapped(_: Any) {
        ESPScheduler.shared.currentSchedule.trigger.days = week.getDecimalConversionOfSelectedDays()
        dismiss(animated: true) {
            self.pvc?.setRepeatStatus()
        }
    }
}

extension SelectDaysViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50.0
        }
        return 40.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            selectAll = !selectAll
            for item in week.daysInWeek {
                item.selected = selectAll
            }
            tableView.reloadData()
        } else {
            let day = week.daysInWeek[indexPath.row - 1]
            day.selected = !day.selected
            let cell = tableView.cellForRow(at: indexPath)
            if day.selected {
                cell?.accessoryType = .checkmark
            } else {
                cell?.accessoryType = .none
            }
            let firstCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
            if week.getDecimalConversionOfSelectedDays() == 127 {
                selectAll = true
                firstCell?.accessoryType = .checkmark
            } else {
                selectAll = false
                firstCell?.accessoryType = .none
            }
        }
    }
}

extension SelectDaysViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return week.daysInWeek.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dayListViewCell")!
        if indexPath.row == 0 {
            cell.textLabel?.text = "Select All"
            if week.getDecimalConversionOfSelectedDays() == 127 {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            let day = week.daysInWeek[indexPath.row - 1]
            cell.textLabel?.text = day.day
            if day.selected {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
}
