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
//  SceneViewController.swift
//  ESPRainMaker
//

import UIKit

class SceneViewController: UIViewController {
    
    static func getVC(isNewScene: Bool) -> SceneViewController {
        let storyboard = UIStoryboard(name: "Scene", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: SceneViewController.storyboardId) as! SceneViewController
        vc.isNewScene = isNewScene
        return vc
    }
    static let storyboardId = "SceneViewController"
    
    var isNewScene: Bool = true
    var deSelectedNodeIDs: [String] = [String]()
    var selectedNodeIDs: [String] = [String]()
    var sceneName: String = ""
    var availableDeviceCopy: [Device] = []
    
    var failedScene: ESPScene?
    
    /*UI elements*/
    @IBOutlet var actionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sceneNameLabel: UILabel!
    var sceneDescription: String = "test"
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var actionListTextView: UITextView!
    
    @IBOutlet weak var descriptionHeader: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var removeSceneButton: RemoveScheduleButton!
    @IBOutlet weak var topBarTopSpace: NSLayoutConstraint!
    @IBOutlet weak var sceneDescriptionLabel: UILabel!
    @IBOutlet weak var nameViewHeight: NSLayoutConstraint!
    
    
    weak var delegate: ServiceUpdateActionsDelegate?
    
    /*Requried variables*/
    var sceneKey: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        
        descriptionTextView.textContainerInset = UIEdgeInsets.zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        
        actionListTextView.textContainer.heightTracksTextView = true
        actionListTextView.isScrollEnabled = false
        actionListTextView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        descriptionTextView.delegate = self
        // Configure view for current scene
        ESPSceneManager.shared.configureDeviceForCurrentScene()
        
        failedScene = getFailedScene(scene: ESPSceneManager.shared.currentScene)
        
        //Get devices already selected for scene
        selectedNodeIDs = getSelectedNodeIDs()
        
        if ESPSceneManager.shared.currentScene.id != nil {
            sceneNameLabel.text = ESPSceneManager.shared.currentScene.name
        } else {
            sceneNameLabel.text = sceneName
        }
        setNameViewHeight(label: sceneNameLabel)
        if let desc = ESPSceneManager.shared.currentScene.info {
            descriptionTextView.text = desc
            self.sceneDescriptionLabel.isHidden = !(desc.count == 0)
        }
        actionListTextView.textContainer.heightTracksTextView = true
        actionListTextView.isScrollEnabled = false
        actionListTextView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        removeSceneButton.isHidden = isNewScene
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        let tapDescGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showKeyBoard))
        self.descriptionHeader.addGestureRecognizer(tapDescGestureRecognizer)
        tapDescGestureRecognizer.cancelsTouchesInView = false
        // Re-order list of devices such that devices whose params are selected be on top.
        for device in ESPSceneManager.shared.availableDevices.values {
            if device.selectedParams > 0 {
                availableDeviceCopy.insert(device, at: 0)
            } else {
                availableDeviceCopy.append(device)
            }
        }
        availableDeviceCopy = configureDeviceSceneActions(availableDeviceCopy)
    }
    
    @objc private func hideKeyBoard() {
        view.endEditing(true)
        topBarTopSpace.constant = 0
        if let desc = self.descriptionTextView.text {
            self.sceneDescriptionLabel.isHidden = !(desc.count == 0)
        }
    }
    
    @objc private func showKeyBoard() {
        self.descriptionTextView.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Show list of actions added on a scene.
        getDeSelectedNodeIDs()
        let actionList = ESPSceneManager.shared.getActionList()
        if actionList == "" {
            if deSelectedNodeIDs.count > 0 {
                saveButton.isHidden = false
            } else {
                saveButton.isHidden = true
            }
            actionListTextView.text = ""
            actionTextViewHeightConstraint.priority = .defaultHigh
        } else {
            actionListTextView.text = actionList
            actionTextViewHeightConstraint.priority = .defaultLow
            saveButton.isHidden = false
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        tabBarController?.tabBar.isHidden = false
        ESPSceneManager.shared.configureDeviceForCurrentScene()
        navigationController?.popViewController(animated: true)
    }
    
    private func getFailedScene(scene: ESPScene) -> ESPScene {
        let failed = ESPScene()
        failed.id = scene.id
        failed.name = scene.name
        failed.actions = scene.actions
        failed.operation = scene.operation
        return failed
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let sceneName = sceneNameLabel.text ?? ""
        if sceneName == "" {
            let alert = UIAlertController(title: "Error", message: ESPSceneConstants.nameNotAddedErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            //If de-selected node count is greater than 0 then call delete on those node ids. Else call edit scene.
            if deSelectedNodeIDs.count > 0 {
                self.deleteNodesForScene() { scenesDeleted in
                    self.editScene(sceneName: sceneName, scenesDeleted: scenesDeleted)
                }
            } else {
                self.editScene(sceneName: sceneName, scenesDeleted: false)
            }
        }
    }
    
    /// Called when user has edited user actions in a scene, or created a new scene.
    /// - Parameter sceneName: scene name
    /// - Parameter scenesDeleted: have scenes been deleted
    private func editScene(sceneName: String, scenesDeleted: Bool) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        // If no id is present that means new scene is added.
        if ESPSceneManager.shared.currentScene != nil, ESPSceneManager.shared.currentScene.id == nil {
            // Generate a unique 4 length id for the new scene.
            ESPSceneManager.shared.currentScene.id = NanoID.new(4)
            ESPSceneManager.shared.currentScene.operation = .add
        } else {
            // Scene already present so will run edit operation on it.
            ESPSceneManager.shared.currentScene.operation = .edit
        }

        // Give value for the scene parameters based on the user selection.
        ESPSceneManager.shared.currentScene.name = sceneName
        if let description = self.descriptionTextView.text {
            ESPSceneManager.shared.currentScene.info = description
        }
        
        // Call save operation.
        ESPSceneManager.shared.saveScene(onView: view) { result  in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Utility.hideLoader(view: self.view)
                switch result {
                case .success(let nodesFailed):
                    // Result is success. Navigate back to scene list and refetch the list.
                    // To check if scene is successfully added.
                    User.shared.updateDeviceList = true
                    if !nodesFailed {
                        if self.isNewScene {
                            self.delegate?.serviceAdded()
                        } else {
                            self.delegate?.serviceUpdated()
                        }
                    }
                    self.formatCurrentSceneKey()
                    self.navigationController?.popToRootViewController(animated: false)
                case .failure:
                    if let failed = self.failedScene {
                        if let key = ESPSceneManager.shared.currentSceneKey, let _ = ESPSceneManager.shared.scenes[key] {
                            ESPSceneManager.shared.scenes[ESPSceneManager.shared.currentSceneKey] = failed
                            ESPSceneManager.shared.scenes[ESPSceneManager.shared.currentSceneKey]?.actions = ESPSceneManager.shared.currentScene.actions
                        }
                    }
                    Utility.showToastMessage(view: self.view, message: ESPSceneConstants.failedToUpdateErrorMessage)
                    if scenesDeleted {
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
    
    private func formatCurrentSceneKey() {
        ESPSceneManager.shared.currentSceneKey = "\(ESPSceneManager.shared.currentScene.id!)"
    }
    
    /// Calls delete action on deselected nodes and returns true if user has edited scene without removing all actions
    /// - Parameter callEditAction: called with flag informing if scene actions have been deleted
    private func deleteNodesForScene(_ callEditAction: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { Utility.showLoader(message: "", view: self.view) }
        ESPSceneManager.shared.deleteSceneNodes(key: ESPSceneManager.shared.currentSceneKey, onView: view, nodeIDs: deSelectedNodeIDs) { result  in
            //If user has deselected all devices, then set update device list to true and pop to scene list screen. Else call edit scene.
            var sceneDevicesDeleted: Bool = false
            switch result {
            case .success(_):
                sceneDevicesDeleted = true
            default:
                sceneDevicesDeleted = false
            }
            let actionList = ESPSceneManager.shared.getActionList()
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                if actionList == "" {
                    Utility.hideLoader(view: self.view)
                    if sceneDevicesDeleted {
                        User.shared.updateDeviceList = true
                        if sceneDevicesDeleted {
                            self.delegate?.serviceRemoved()
                        }
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                } else {
                    callEditAction(sceneDevicesDeleted)
                }
            })
        }
    }
    
    @IBAction func sceneNamePressed(_ sender: Any) {
        let input = UIAlertController(title: "Add name", message: "Choose name for your scene", preferredStyle: .alert)
        input.addTextField { textField in
            textField.text = self.sceneNameLabel.text ?? ""
            textField.tag = 200
            textField.delegate = self
            self.addHeightConstraint(textField: textField)
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            textField?.keyboardType = .asciiCapable
            guard let name = textField?.text else {
                return
            }
            self.sceneNameLabel.text = name
            self.setNameViewHeight(label: self.sceneNameLabel)
        }))
        present(input, animated: true, completion: nil)
    }
    
    @IBAction func actionsPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Scene", bundle: nil)
        let selectDeviceVC = storyboard.instantiateViewController(withIdentifier: "SceneSelectDevicesVC") as! SceneSelectDevicesVC
        // Re-order list of devices such that devices whose params are selected be on top.
        selectDeviceVC.availableDeviceCopy = sortDevices(availableDevices: availableDeviceCopy)
        navigationController?.pushViewController(selectDeviceVC, animated: true)
    }
    
    @IBAction func removeScene(_ sender: Any) {
        let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            if let key = ESPSceneManager.shared.currentSceneKey {
                Utility.showLoader(message: "", view: self.view)
                ESPSceneManager.shared.deleteSceneAt(key: key, onView: self.view) { result in
                    Utility.hideLoader(view: self.view)
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let nodesFailed):
                            User.shared.updateDeviceList = true
                            if !nodesFailed {
                                self.delegate?.serviceRemoved()
                            }
                            self.navigationController?.popViewController(animated: true)
                        case .failure:
                            Utility.showToastMessage(view: self.view, message: ESPSceneConstants.deleteSceneFailureMessage)
                            break
                        }
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    /// Set scene action status for a device to allowed (if said device is online) if scene already has a device from the same node
    /// - Parameter availableDevices: list of available devices
    /// - Returns: list of available devices after configuration
    private func configureDeviceSceneActions(_ availableDevices: [Device]) -> [Device] {
        var finalDevicesList = [Device]()
        var selectedCount = 0
        var deSelectedCount = 0
        for device in availableDevices {
            //Sort devices such that selected devices are on top and not selected devices are on bottom
            device.sceneActionStatus = nil
            if device.selectedParams > 0 {
                switch device.sceneAction {
                case .deviceOffline:
                    device.sceneActionStatus = .deviceOffline
                default:
                    device.sceneActionStatus = .allowed
                }
                finalDevicesList.insert(device, at: selectedCount)
                selectedCount+=1
            } else {
                device.sceneActionStatus = device.sceneAction
                finalDevicesList.insert(device, at: selectedCount+deSelectedCount)
                deSelectedCount+=1
            }
        }
        return finalDevicesList
    }
    
    /// Sort devices in the following order [allowed devices, max reached devices, offline devices]
    /// - Parameter availableDevices: list of avaiable devices
    /// - Returns: list of avaiable devices after sorting
    private func sortDevices(availableDevices: [Device]) -> [Device] {
        var devices = [Device]()
        var availableCount = 0
        var maxReachedCount = 0
        var offlineCount = 0
        for device in availableDevices {
            let status = device.sceneAction
            switch status {
            case .allowed:
                devices.insert(device, at: availableCount)
                availableCount+=1
            case .maxSceneReached(_):
                devices.insert(device, at: availableCount+maxReachedCount)
                maxReachedCount+=1
            case .deviceOffline:
                devices.insert(device, at: availableCount+maxReachedCount+offlineCount)
                offlineCount+=1
            }
        }
        return devices
    }
    
    /// Set height for the schedule name label
    /// - Parameter label: schedule name label
    private func setNameViewHeight(label: UILabel) {
        let height = self.sceneNameLabel.getNameViewHeight(height: self.nameViewHeight.constant, width: self.view.frame.width - 127.0)
        self.nameViewHeight.constant = height
    }
    
    /// Add height constraint on textfield
    /// - Parameter textField: textField
    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }
    
    /// Get list of node IDs for which some action has been selected
    /// - Returns: list of selected node IDs
    private func getSelectedNodeIDs() -> [String] {
        var nodeIDs: [String] = [String]()
        for device in ESPSceneManager.shared.availableDevices.values {
            if let node = device.node, let nodeID = node.node_id {
                if device.selectedParams > 0, !nodeIDs.contains(nodeID) {
                    nodeIDs.append(nodeID)
                }
            }
        }
        return nodeIDs
    }
    
    /// Get list of node IDs for which actions have been removed from the original selected nodes.
    /// - Returns: list of deselected node IDs
    private func getDeSelectedNodeIDs() {
        let nodeIDs = getSelectedNodeIDs()
        deSelectedNodeIDs = [String]()
        for nodeID in selectedNodeIDs {
            if !nodeIDs.contains(nodeID) {
                deSelectedNodeIDs.append(nodeID)
            }
        }
    }
    
}

extension SceneViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Restrict the length of name of scene to be equal to or less than 32 characters.
        let maxLength = 32
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}

extension SceneViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let height = descriptionTextView.frame.height - 120
        if height > 0 {
            topBarTopSpace.constant = -(height)
        }
        self.sceneDescriptionLabel.isHidden = true
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.tag == 100 {
            if text == "\n" || text.contains("\n") {
                hideKeyBoard()
                return false
            }
            let height = descriptionTextView.frame.height - 120
            if height > 0 {
                topBarTopSpace.constant = -(height)
            }
            let originalText = textView.text
            guard let stringRange = Range(range, in: originalText!) else { return false }
            let updatedText = originalText!.replacingCharacters(in: stringRange, with: text)
            let lineHeight = "A".getViewHeight(labelWidth: self.descriptionTextView.frame.width, font: descriptionTextView.font!) - descriptionTextView.textContainerInset.top - descriptionTextView.textContainerInset.bottom - 0.5
            let rows: Int = Int((descriptionTextView.contentSize.height - descriptionTextView.textContainerInset.top - descriptionTextView.textContainerInset.bottom) / lineHeight)
            if rows > 15 {
                if updatedText.count < originalText!.count {
                    return true
                } else {
                    return false
                }
            }
            return (textView.text.count + (text.count - range.length) <= 100)
        }
        return true
    }
}
