// Copyright 2021 Espressif Systems
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
//  NewNodeGroupViewController.swift
//  ESPRainMaker
//

import UIKit

class NewNodeGroupViewController: UIViewController {
    // IB Outlets
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add gesture recognizer to hide keyboard(if open) on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureRecognizer)

        // If user do not have associated nodes then skip option to add device in group
        if User.shared.associatedNodeList?.count ?? 0 < 1 {
            nextButton.setTitle("Add", for: .normal)
        }

        // Make group name textfield as first responder
        if nameTextField.text?.count ?? 0 < 1 {
            nameTextField.becomeFirstResponder()
        }
        // Observe change in text of name field
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
    }

    // MARK: - Private Methods

    @objc private func textFieldDidChange() {
        if nameTextField.text?.count ?? 0 > 0 {
            nextButton.isEnabled = true
            nextButton.alpha = 1.0
        } else {
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
        }
    }

    @objc private func hideKeyBoard() {
        nameTextField.resignFirstResponder()
        view.endEditing(true)
    }

    // MARK: - IB Actions

    @IBAction func nameButtonPressed(_: Any) {
        nameTextField.becomeFirstResponder()
    }

    @IBAction func cancelButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func nextButtonPressed(_: Any) {
        // Hides keyboard
        view.endEditing(true)
        // Navigate to screen for selecting node in the new group
        let newNodeGroup = NodeGroup()
        newNodeGroup.group_name = nameTextField.text
        if User.shared.associatedNodeList?.count ?? 0 > 0 {
            let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
            let selectGroupNodesVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "selectGroupNodesVC") as! SelectGroupNodesViewController
            selectGroupNodesVC.newGroup = newNodeGroup
            navigationController?.pushViewController(selectGroupNodesVC, animated: true)
        } else {
            // In case where no device is present, directly create new group
            Utility.showLoader(message: "Creating new group...", view: view)
            NodeGroupManager.shared.createNodeGroup(group: newNodeGroup) { newGroup, error in
                Utility.hideLoader(view: self.view)
                guard let createGroupError = error else {
                    let insertionIndex = NodeGroupManager.shared.nodeGroups.insertionIndexOf(newGroup!, isOrderedBefore: { $0.group_name ?? "" < $1.group_name ?? "" })
                    NodeGroupManager.shared.nodeGroups.insert(newGroup!, at: insertionIndex)
                    NodeGroupManager.shared.listUpdated = true
                    User.shared.updateDeviceList = true
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                    return
                }
                Utility.showToastMessage(view: self.view, message: createGroupError.description, duration: 5.0)
            }
        }
    }
}

extension NewNodeGroupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
