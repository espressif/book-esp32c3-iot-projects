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
//  DevicesViewController.swift
//  ESPRainMaker
//

import Alamofire
import Foundation
import JWTDecode
import MBProgressHUD
import UIKit

class DevicesViewController: UIViewController {
    // IB outlets
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var emptyListIcon: UIImageView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!
    @IBOutlet var loadingIndicator: SpinnerView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var dropDownMenu: UIView!
    @IBOutlet var segmentControlLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var groupMenuButton: UIButton!

    let controlStoryBoard = UIStoryboard(name: "DeviceDetail", bundle: nil)
    let localStorageHandler = ESPLocalStorageHandler()
    var checkDeviceAssociation = false
    private var currentPage = 0
    private var absoluteSegmentPosition: [CGFloat] = []
    
    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if user session is valid
        let service = ESPExtendSessionService(presenter: self)
        service.validateUserSession()
        
        // Get info of user from user default
        if User.shared.isUserSessionActive {
            collectionView.isUserInteractionEnabled = false
            collectionView.isHidden = false
            // Fetch associated nodes from local storage
            User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
            if Configuration.shared.appConfiguration.supportGrouping {
                NodeGroupManager.shared.nodeGroups = localStorageHandler.fetchNodeGroups() ?? []
            }
            User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
            refreshDeviceList()
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.configureRemoteNotifications()
        } else {
            refresh()
        }

        dropDownMenu.dropShadow()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
        // Register nib
        collectionView.register(UINib(nibName: "DeviceGroupEmptyDeviceCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "deviceGroupEmptyDeviceCVC")

        // Add gesture to hide Group DropDown menu
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideDropDown))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        if !Configuration.shared.appConfiguration.supportGrouping {
            segmentControl.isHidden = true
            groupMenuButton.isHidden = true
        } else {
            configureSegmentControl()
        }
        
        if !Configuration.shared.appConfiguration.supportSchedule {
            tabBarController?.viewControllers?.remove(at: 1)
        }
        if !Configuration.shared.appConfiguration.supportScene {
            tabBarController?.viewControllers?.remove(at: 2)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkNetworkUpdate()
        if User.shared.updateUserInfo {
            User.shared.updateUserInfo = false
            updateUserInfo()
        }
        if User.shared.isUserSessionActive {
            if User.shared.updateDeviceList {
                refreshDeviceList()
            }
        }
        setViewForNoNodes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButton?.setImage(UIImage(named: "add_icon"), for: .normal)
        dropDownMenu?.isHidden = true
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localNetworkUpdate), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: Notification.Name(Constants.reloadCollectionView), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.refreshDeviceList), object: nil)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Observer functions

    @objc func hideDropDown() {
        dropDownMenu.isHidden = true
    }

    @objc func reloadCollectionView() {
        collectionView.reloadData()
    }

    @objc func appEnterForeground() {
        refreshDeviceList()
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

    @objc func localNetworkUpdate() {
        collectionView.reloadData()
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
        }
    }

    @objc func refreshDeviceList() {
        showLoader()
        collectionView.isUserInteractionEnabled = false
        User.shared.updateDeviceList = false

        NetworkManager.shared.getNodes { nodes, error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                User.shared.associatedNodeList = nil
                if error != nil {
                    self.searchForDevicesOnWLAN()
                    self.unhideInitialView(error: error)
                    self.collectionView.isUserInteractionEnabled = true
                    return
                }
                User.shared.associatedNodeList = nodes

                if Configuration.shared.appConfiguration.supportGrouping {
                    NodeGroupManager.shared.getNodeGroups { _, error in
                        self.searchForDevicesOnWLAN()
                        if error != nil {
                            Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                        }
                        self.setupSegmentControl()
                        self.prepareView()
                    }
                } else {
                    self.searchForDevicesOnWLAN()
                    self.prepareView()
                }
            }
        }
    }

    // MARK: - IB Actions

    @IBAction func clickedSegment(segment: UISegmentedControl) {
        print(segment.selectedSegmentIndex)
        if segment.selectedSegmentIndex > currentPage {
            collectionView.scrollToItem(at: IndexPath(row: segment.selectedSegmentIndex, section: 0), at: .right, animated: true)
        } else {
            collectionView.scrollToItem(at: IndexPath(row: segment.selectedSegmentIndex, section: 0), at: .left, animated: true)
        }
        adjustSegmentControlFor(currentIndex: segment.selectedSegmentIndex)
        currentPage = segment.selectedSegmentIndex
    }

    @IBAction func refreshClicked(_: Any) {
        refreshDeviceList()
    }

    @IBAction func dropDownClicked(_: Any) {
        dropDownMenu.isHidden = !dropDownMenu.isHidden
    }

    @IBAction func goToNodeGroups(_: Any) {
        let controlStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: "nodeGroupsVC") as! NodeGroupsViewController
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    @IBAction func addNodeGroup(_: Any) {
        let controlStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: "createGroupVC") as! NewNodeGroupViewController
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    @IBAction func addDeviceClicked(_: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        tabBarController?.tabBar.isHidden = true

        // Check if scan is enabled in ap
        if Configuration.shared.espProvSetting.scanEnabled {
            let scannerVC = mainStoryboard.instantiateViewController(withIdentifier: "scannerVC") as! ScannerViewController
            navigationController?.pushViewController(scannerVC, animated: true)
        } else {
            // If scan is not enabled check supported transport
            switch Configuration.shared.espProvSetting.transport {
            case .ble:
                // Go directly to BLE manual provisioing
                goToBleProvision()
            case .softAp:
                // Go directly to SoftAP manual provisioing
                goToSoftAPProvision()
            default:
                // If both BLE and SoftAP is supported. Present Action Sheet to give option to choose.
                let actionSheet = UIAlertController(title: "", message: "Choose Provisioning Transport", preferredStyle: .actionSheet)
                let bleAction = UIAlertAction(title: "BLE", style: .default) { _ in
                    self.goToBleProvision()
                }
                let softapAction = UIAlertAction(title: "SoftAP", style: .default) { _ in
                    self.goToSoftAPProvision()
                }
                actionSheet.addAction(bleAction)
                actionSheet.addAction(softapAction)
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(actionSheet, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Private Methods
    
    private func searchForDevicesOnWLAN() {
        DispatchQueue.main.async {
            // Start local discovery if its enabled
            if Configuration.shared.appConfiguration.supportLocalControl {
                User.shared.startServiceDiscovery()
            }
        }
    }

    private func goToBleProvision() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let bleLandingVC = mainStoryboard.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }

    private func goToSoftAPProvision() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let softLandingVC = mainStoryboard.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
        navigationController?.pushViewController(softLandingVC, animated: true)
    }

    private func prepareView() {
        if User.shared.associatedNodeList == nil || User.shared.associatedNodeList?.count == 0 {
            setViewForNoNodes()
        } else {
            initialView.isHidden = true
            collectionView.isHidden = false
            addButton.isHidden = false
            collectionView.reloadData()
        }
        collectionView.isUserInteractionEnabled = true
    }

    private func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.animate()
    }

    private func updateUserInfo() {
        let sessionWorker = ESPExtendUserSessionWorker()
        sessionWorker.checkUserSession() { _, error in
            if error == nil, let idToken = ESPTokenWorker.shared.idTokenString {
                if User.shared.userInfo.loggedInWith == .cognito {
                    self.getUserInfo(token: idToken, provider: .cognito)
                } else {
                    self.getUserInfo(token: idToken, provider: .other)
                }
            } else {
                Utility.hideLoader(view: self.view)
                self.refreshDeviceList()
            }
        }
    }
    
    private func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        refreshDeviceList()
    }
    
    private func refresh() {
        let service = ESPUserService(presenter: self)
        service.fetchUserDetails()
    }

    private func setViewForNoNodes() {
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No Device Added"
            emptyListIcon.image = UIImage(named: "no_device_icon")
            infoLabel.textColor = .white
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        }
    }

    private func setupSegmentControl() {
        segmentControlLeadingConstraint.constant = 0
        segmentControl.layoutIfNeeded()
        segmentControl.removeAllSegments()
        absoluteSegmentPosition = []

        var segmentPosition: CGFloat = 0
        for i in 0 ... NodeGroupManager.shared.nodeGroups.count {
            var stringBoundingbox: CGSize = .zero
            if i == 0 {
                stringBoundingbox = "All Devices".size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold)])
                segmentControl.insertSegment(withTitle: "All Devices", at: i, animated: false)
            } else {
                let groupName = NodeGroupManager.shared.nodeGroups[i - 1].group_name ?? ""
                stringBoundingbox = (groupName as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold)])
                segmentControl.insertSegment(withTitle: groupName, at: i, animated: false)
            }
            segmentPosition = segmentPosition + stringBoundingbox.width + 20
            absoluteSegmentPosition.append(segmentPosition)
            segmentControl.setWidth(stringBoundingbox.width + 20, forSegmentAt: i)
        }
        if currentPage > NodeGroupManager.shared.nodeGroups.count {
            segmentControl.selectedSegmentIndex = NodeGroupManager.shared.nodeGroups.count
        } else {
            segmentControl.selectedSegmentIndex = currentPage
        }
    }

    private func getFontWidthForString(text: NSString) -> CGSize {
        return text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.5, weight: .semibold)])
    }

    private func getSingleDeviceNodeCount(forNodeList: [Node]?) -> Int {
        var singleDeviceNodeCount = 0
        if let nodeList = forNodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
        return singleDeviceNodeCount
    }

    // Helper method to customise UISegmentControl
    private func configureSegmentControl() {
        let currentBGColor = UIColor(hexString: "#8265E3")
        segmentControl.removeBorder()
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0, weight: .regular)], for: .normal)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold), NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue], for: .selected)
        segmentControl.changeUnderlineColor(color: currentBGColor)
        let allDeviceSize = getFontWidthForString(text: "All Devices")
        segmentControl.setWidth(allDeviceSize.width + 40, forSegmentAt: 0)
    }

    private func unhideInitialView(error: ESPNetworkError?) {
        User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No devices to show\n" + (error?.description ?? "Something went wrong!!")
            emptyListIcon.image = nil
            infoLabel.textColor = .red
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        } else {
            collectionView.reloadData()
            initialView.isHidden = true
            collectionView.isHidden = false
            addButton.isHidden = false
            Utility.showToastMessage(view: view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
        }
        if Configuration.shared.appConfiguration.supportGrouping {
            NodeGroupManager.shared.nodeGroups = localStorageHandler.fetchNodeGroups() ?? []
            setupSegmentControl()
            prepareView()
        }
    }

    private func preparePopover(contentController: UIViewController,
                                sender: UIView,
                                delegate: UIPopoverPresentationControllerDelegate?)
    {
        contentController.modalPresentationStyle = .popover
        contentController.popoverPresentationController!.sourceView = sender
        contentController.popoverPresentationController!.sourceRect = sender.bounds
        contentController.preferredContentSize = CGSize(width: 182.0, height: 112.0)
        contentController.popoverPresentationController!.delegate = delegate
    }

    private func adjustSegmentControlFor(currentIndex: Int) {
        if absoluteSegmentPosition[currentIndex] > UIScreen.main.bounds.size.width - 100 {
            UIView.animate(withDuration: 0.5) {
                self.segmentControlLeadingConstraint.constant = UIScreen.main.bounds.size.width - 80 - 20 - self.absoluteSegmentPosition[currentIndex]
                self.segmentControl.layoutIfNeeded()
            }
        } else {
            if segmentControlLeadingConstraint.constant != 0 {
                UIView.animate(withDuration: 0.5) {
                    self.segmentControlLeadingConstraint.constant = 0
                    self.segmentControl.layoutIfNeeded()
                }
            }
        }
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x / w))
        self.currentPage = currentPage
        segmentControl.selectedSegmentIndex = currentPage
        adjustSegmentControlFor(currentIndex: currentPage)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if Configuration.shared.appConfiguration.supportGrouping {
            if NodeGroupManager.shared.nodeGroups.count == 0 {
                if User.shared.associatedNodeList == nil || User.shared.associatedNodeList?.count == 0 {
                    return 0
                } else {
                    return 1
                }
            }
            return NodeGroupManager.shared.nodeGroups.count + 1
        }
        return 1
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item > 0 {
            let group = NodeGroupManager.shared.nodeGroups[indexPath.item - 1]
            if group.nodes?.count ?? 0 < 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceGroupEmptyDeviceCVC", for: indexPath) as! DeviceGroupEmptyDeviceCollectionViewCell
                cell.addDeviceButtonAction = {
                    let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
                    let editNodeGroupVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "editNodeGroupVC") as! EditNodeGroupViewController
                    editNodeGroupVC.currentNodeGroup = group
                    self.navigationController?.pushViewController(editNodeGroupVC, animated: true)
                }
                return cell
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceGroupCollectionViewCell", for: indexPath) as! DeviceGroupCollectionViewCell
        cell.delegate = self
        if indexPath.item == 0 {
            cell.singleDeviceNodeCount = getSingleDeviceNodeCount(forNodeList: User.shared.associatedNodeList)
            cell.datasource = User.shared.associatedNodeList ?? []
        } else {
            let nodeList = NodeGroupManager.shared.nodeGroups[indexPath.item - 1].nodeList
            cell.singleDeviceNodeCount = getSingleDeviceNodeCount(forNodeList: nodeList)
            cell.datasource = nodeList ?? []
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(cell, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.tintColor = .clear
        cell.collectionView.refreshControl = refreshControl
        cell.refreshAction = {
            refreshControl.endRefreshing()
            self.refreshDeviceList()
        }
        cell.collectionView.reloadData()
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let frame = collectionView.frame
        return CGSize(width: frame.width, height: frame.height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension DevicesViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_: UIPopoverPresentationController) {}

    func popoverPresentationControllerShouldDismissPopover(_: UIPopoverPresentationController) -> Bool {
        return false
    }
}

extension DevicesViewController: DeviceGroupCollectionViewCellDelegate {
    func didSelectDevice(device: Device) {
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: Constants.deviceTraitListVCIdentifier) as! DeviceTraitListViewController
        deviceTraitsVC.device = device

        Utility.hideLoader(view: view)
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    func didSelectNode(node: Node) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
        destination.currentNode = node
        navigationController?.pushViewController(destination, animated: true)
    }
}

extension DevicesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == groupMenuButton {
            return false
        }

        return true
    }
}


extension DevicesViewController: ESPExtendSessionPresentationLogic {
    
    func sessionValidated(withError error: ESPAPIError?) {
        if error != nil {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
                if let _ = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                    nav.modalPresentationStyle = .fullScreen
                    tab.present(nav, animated: true, completion: nil)
                }
            }
        }
    }
}

extension DevicesViewController: ESPUserPresentationLogic {
    
    func userDetailsFetched(error: ESPAPIError?) {
        if error == nil {
            DispatchQueue.main.async {
                self.updateUserInfo()
            }
        }
    }
}
