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
//  SceneListViewController.swift
//  ESPRainMaker
//

import UIKit

class SceneListViewController: UIViewController {
    
    static func getVC() -> SceneListViewController {
        let storyboard = UIStoryboard(name: "Scene", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: SceneListViewController.storyboardId) as! SceneListViewController
        return vc
    }
    
    static let storyboardId = "SceneListViewController"
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editButton: BarButton!
    @IBOutlet var addSceneButton: PrimaryButton!
    @IBOutlet var initialLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!
    
    private let refreshControl = UIRefreshControl()
    var scenesList = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide nav bar
        navigationController?.navigationBar.isHidden = true
        editButton.setTitleColor(.white, for: .normal)
        
        //setup table view UI
        setupTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.isEditing = false
        editButton.setTitle("Edit", for: .normal)
        ESPSceneManager.shared.currentSceneKey = nil
        // Show UI based on scene list count
        if User.shared.updateDeviceList {
            User.shared.updateDeviceList = false
            Utility.showLoader(message: "", view: view)
            refreshSceneList(self)
        } else {
            showScenesList()
        }
        checkNetworkUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
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
    
    //MARK: IBActions
    @IBAction func refreshSceneList(_ sender: Any) {
        refreshControl.endRefreshing()
        NetworkManager.shared.getNodes { nodes, error in
            Utility.hideLoader(view: self.view)
            if error != nil {
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
                }
            } else {
                User.shared.associatedNodeList = nodes
                DispatchQueue.main.async {
                    self.showScenesList()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    @IBAction func addSceneButtonPressed(_ sender: Any) {
        self.addScene()
    }
    
    
    @IBAction func addButton(_ sender: Any) {
        self.addScene()
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        tableView.isEditing = !tableView.isEditing
        if let button = sender as? UIButton {
            button.setTitle(tableView.isEditing ? "Done" : "Edit", for: .normal)
        }
    }
    
    //MARK: Private methods
    
    private func setupTable() {
        tableView.tableFooterView = UIView()
        
        //refresh control
        refreshControl.addTarget(self, action: #selector(refreshSceneList(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        tableView.refreshControl = refreshControl
        
        //get list of scenes
        showScenesList()
        
        addSceneButton.isUserInteractionEnabled = true
    }
    
    private func addScene() {
        let input = UIAlertController(title: "Add name", message: "Choose name for your scene", preferredStyle: .alert)
        input.addTextField { textField in
            textField.delegate = self
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            textField?.keyboardType = .asciiCapable
            guard let name = textField?.text, name.count > 0 else {
                //show name error alert
                self.showErrorAlert(title: "Error", message: "Please enter a name for the scene to proceed.", buttonTitle: "OK", callback: {
                    self.addScene()
                })
                return
            }
            self.createNewScene(name: name)
        }))
        present(input, animated: true, completion: nil)
    }
    
    private func createNewScene(name: String) {
        let sceneVC = SceneViewController.getVC(isNewScene: true)
        sceneVC.sceneName = name
        let scene = ESPScene()
        scene.name = name
        ESPSceneManager.shared.currentScene = scene
        sceneVC.delegate = self
        navigationController?.pushViewController(sceneVC, animated: true)
    }
    
    private func showScenesList() {
        getScenesList()
        if ESPSceneManager.shared.availableDevices.count < 1 {
            initialLabel.text = "You don't have any device \n that supports this."
        } else if scenesList.count < 1 {
            initialLabel.text = "No Scenes added."
        }
        self.addSceneButton.isHidden = (ESPSceneManager.shared.availableDevices.count < 1)
        let areScenesPresent = scenesList.count>0 ? true : false
        self.editButton.isHidden = !areScenesPresent
        self.initialView.isHidden = areScenesPresent
        self.addButton.isHidden = !areScenesPresent
        tableView.isHidden = !areScenesPresent
        tableView.reloadData()
    }
    
    private func getScenesList() {
        scenesList.removeAll()
        scenesList = [String](ESPSceneManager.shared.scenes.keys).sorted(by: { first, second -> Bool in
            // Sorting schedule list by time
            let firstArray = first.components(separatedBy: ".")
            let firstName = firstArray[1]
            let secondArray = second.components(separatedBy: ".")
            let secondName = secondArray[1]
            return firstName < secondName
        })
        tableView.reloadData()
    }
}

extension SceneListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row % 2 != 0 {
            return 20.0
        }
        var text = ""
        if indexPath.row/2 < scenesList.count {
            let id = scenesList[indexPath.row/2]
            let scene = ESPSceneManager.shared.scenes[id]!
            if let info = scene.info {
                text = info.replacingOccurrences(of: "\n", with: " ")
            } else {
                ESPSceneManager.shared.currentScene = scene
                text = ESPSceneManager.shared.getActionList()
            }
        }
        let singleLineHeight = "*".getViewHeight(labelWidth: tableView.frame.width-(0.22*tableView.frame.width+51.5), font: UIFont.systemFont(ofSize: 11.0, weight: .regular))
        let height = text.getViewHeight(labelWidth: tableView.frame.width-(0.22*tableView.frame.width+51.5), font: UIFont.systemFont(ofSize: 11.0, weight: .regular))
        return 80.0 + height - singleLineHeight
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row % 2 != 0 {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        let sceneVC = SceneViewController.getVC(isNewScene: false)
        ESPSceneManager.shared.currentScene = ESPSceneManager.shared.scenes[scenesList[indexPath.row/2]]!
        sceneVC.sceneKey = scenesList[indexPath.row/2]
        ESPSceneManager.shared.currentSceneKey = scenesList[indexPath.row/2]
        sceneVC.delegate = self
        navigationController?.pushViewController(sceneVC, animated: true)
    }
    
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect.zero)
        return view
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 2*scenesList.count
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 != 0 {
            let cell = UITableViewCell(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 20.0))
            cell.contentView.backgroundColor = .clear
            cell.isUserInteractionEnabled = false
            cell.backgroundColor = .clear
            cell.isHidden = true
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: SceneListCell.reuseIdentifier, for: indexPath) as? SceneListCell {
            if indexPath.row/2 < scenesList.count {
                let id = scenesList[indexPath.row/2]
                let scene = ESPSceneManager.shared.scenes[id]!
                ESPSceneManager.shared.currentScene = scene
                ESPSceneManager.shared.configureDeviceForCurrentScene()
//                cell.scene = scene
                cell.scene = ESPSceneManager.shared.currentScene
                if let scene = ESPSceneManager.shared.scenes[id] {
                    cell.sceneName.text = scene.name
                    if let info = scene.info, info.count > 0 {
                        cell.sceneDevicesList.text = info.replacingOccurrences(of: "\n", with: " ")
                    } else {
                        cell.sceneDevicesList.text = ESPSceneManager.shared.getActionList()
                    }
                }
                cell.layer.cornerRadius = 10.0
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row % 2 != 0 {
            return
        }
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                    ESPSceneManager.shared.deleteSceneAt(key: self.scenesList[indexPath.row/2], onView: self.view) { result in
                        switch result {
                        case .success(let nodesFailed):
                            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                                if !nodesFailed {
                                    Utility.showToastMessage(view: self.view, message: ESPSceneConstants.sceneDeletedSuccessMessage, duration: 2.0)
                                }
                                self.refreshSceneList(self)
                            })
                        default:
                            Utility.hideLoader(view: self.view)
                            Utility.showToastMessage(view: self.view, message: ESPSceneConstants.deleteSceneFailureMessage, duration: 1.5)
                        }
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension SceneListViewController: SceneListCellDelegate {
    
    func activateScenePressed(_ scene: ESPScene?) {
        var resultScene = scene
        ESPSceneManager.shared.currentScene = resultScene
        ESPSceneManager.shared.configureDeviceForCurrentScene()
        resultScene = ESPSceneManager.shared.currentScene
        if let resultScene = resultScene {
            Utility.showLoader(message: "", view: self.view)
            ESPSceneManager.shared.activateScene(scene: resultScene, onView: self.view, completionHandler: { result in
                Utility.hideLoader(view: self.view)
                switch result {
                case .success(let nodesFailed):
                    if !nodesFailed {
                        Utility.showToastMessage(view: self.view, message: ESPSceneConstants.activateSceneSuccessMessage, duration: 1.5)
                    }
                case .failure:
                    Utility.showToastMessage(view: self.view, message: ESPSceneConstants.activateSceneFailureMessage, duration: 1.5)
                    break
                }
            })
        }
    }
}

extension SceneListViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Restrict the length of name of scene to be equal to or less than 32 characters.
        let maxLength = 32
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}

extension SceneListViewController: ServiceUpdateActionsDelegate {
    
    func serviceAdded() {
        Utility.showToastMessage(view: self.view, message: ESPSceneConstants.sceneAddedSuccessMessage, duration: 2.0)
    }
    
    func serviceUpdated() {
        Utility.showToastMessage(view: self.view, message: ESPSceneConstants.sceneUpdatedSuccessMessage, duration: 2.0)
    }
    
    func serviceRemoved() {
        Utility.showToastMessage(view: self.view, message: ESPSceneConstants.sceneDeletedSuccessMessage, duration: 2.0)
    }
}
