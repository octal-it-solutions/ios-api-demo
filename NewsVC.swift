//
//  NewsVC.swift
//  Horyaal
//
//  Created by kshitij godara on 15/06/21.
//

import UIKit

class NewsCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var imgViewIcon: UIImageView!
}

class NewsVC: UIViewController {
    
    @IBOutlet var tblView : UITableView!
    @IBOutlet var lblTitle : UILabel!
    
    var refreshControl = UIRefreshControl()
    
    var arrNewsData : [NewsDataModel]?
    
    @IBOutlet var containerViewBottom : UIView!
    var controllerDraft : DraftVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.isNavigationBarHidden = true
        
        self.title = "News".cuslocalized
        
        if self.revealViewController() != nil {
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().rearViewRevealWidth = self.view.frame.width - 100.0
        }
        
        lblTitle.text = "News".cuslocalized
        let strTitle = "Pull down to refresh".cuslocalized
        refreshControl.attributedTitle = NSAttributedString(string: strTitle)
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tblView.addSubview(refreshControl) // not required when using UITableViewController
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        controllerDraft = storyboard.instantiateViewController(withIdentifier: "DraftVC") as? DraftVC

        
        
    }
    
    @objc func refresh(_ sender: AnyObject) {
       // Code to refresh table view
        defer {
        }
        do {
            let strTitle = "Updating".cuslocalized
            refreshControl.attributedTitle = NSAttributedString(string: strTitle)
//            refreshControl.tintColor = UIColor.red
            
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                Thread.sleep(forTimeInterval: 2)
                
                DispatchQueue.main.async(execute: {() -> Void in
                    self.arrNewsData?.removeAll()
                    self.getNewsListingFromAPI()
                    self.refreshControl.endRefreshing()
                })
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view.
        if self.revealViewController() != nil
        {
            self.revealViewController().delegate=self
        }
        
        callSubscriptionIsAvailable()
//        getNewsListingFromAPI()
        showBottomPopup()
    }
    
    func showBottomPopup() {
        
        if (Constant.kAppDelegate.arrOddsAppDelegate.count >= Constant.kAppDelegate.minimumMatchesAppDelegate) && (Constant.kAppDelegate.minimumMatchesAppDelegate > 0) {
            
            containerViewBottom.isHidden = false
            controllerDraft!.view.frame = containerViewBottom.bounds
            controllerDraft?.btnClose.addTarget(self, action: #selector(self.dismissViewFromParent(_:)), for: .touchUpInside)
            containerViewBottom.addSubview(controllerDraft!.view)
            
            controllerDraft?.lblDraftCaption.text = "Draft matches".cuslocalized
            controllerDraft?.lblDraftValue.text = String(format: "%d %@", Constant.kAppDelegate.arrOddsAppDelegate.count,"matches are selected".cuslocalized)
            
            controllerDraft?.btnView.addTarget(self, action: #selector(self.seeSelectedOddsViewFromParent(_:)), for: .touchUpInside)
            
            self.addChild(controllerDraft!)
            controllerDraft!.didMove(toParent: self)
        }
    }
    
    @objc func seeSelectedOddsViewFromParent(_ senderBtn: UIButton){ //<- needs `@objc`
        print("\(senderBtn.tag)")
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OddMatchVC") as? OddMatchVC
        vc?.hidesBottomBarWhenPushed = true
        
//        let arr = self.arrMatches.filter{return $0.isSelected == true}
//        let arrOfIds : [String] = arr.map{return $0.matchID ?? "0"}
        let arrOfIds : [String] = Constant.kAppDelegate.arrOddsAppDelegate.map{return String($0.matchID ?? 0)}
        let stringRepresentation = arrOfIds.joined(separator: ",")// "1-2-3"
        vc?.strOddsInCommaSepratedFormat = stringRepresentation
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @objc func dismissViewFromParent(_ senderBtn: UIButton){ //<- needs `@objc`
        print("\(senderBtn.tag)")
        
        DispatchQueue.main.async() {
            self.presentAlertWith(title : "",message: "Are you sure?".cuslocalized, oktitle: "Yes".cuslocalized, notitle: "No".cuslocalized, okaction: {
                self.controllerDraft!.willMove(toParent: nil)
                self.controllerDraft!.view.removeFromSuperview()
                self.controllerDraft!.removeFromParent()
                self.containerViewBottom.isHidden = true
                
                Constant.kAppDelegate.arrOddsAppDelegate.removeAll()
                Constant.kAppDelegate.minimumMatchesAppDelegate = 0
                Constant.kAppDelegate.ticketParentId = 0
                Constant.kAppDelegate.stringRepresentation = ""
            }) {
                
            }
        }
        
    }
    
    @IBAction func leftBarButtonClicked(){
        self.revealViewController().revealToggle(self)
    }
    
    func getNewsListingFromAPI() {
        
        let strUrl : String = String(format: "%@", Constant.kNewsAPI)
        WebServiceHelper.getRequest(method: strUrl, isApplySubscription: "false", params: [:] as AnyObject) { (success, data, error, responseHeader) in
            
                    DispatchQueue.main.async(execute: {
                        if let dictionary = data as? [String:Any]
                        {
                            if let array = dictionary["Results"] as? [[String:Any]]
                            {
                                DispatchQueue.main.async(execute: {
                                    do{
                                        let jsonData = try JSONSerialization.data(withJSONObject: array ?? [], options: .prettyPrinted)
                                        self.arrNewsData = try? JSONDecoder().decode([NewsDataModel].self, from: jsonData)
                                        self.tblView.reloadData()
                                    }catch let error {
                                        print(error)
                                    }
                                })
                            }
                            
                        }
                    })
        }
    }
    
    func callSubscriptionIsAvailable() {
        
        WebServiceHelper.getRequest(method: Constant.kGetSubscription, params: [:] as AnyObject) { (success, data, error, responseHeader) in
            
            if let httpResponse = responseHeader as? HTTPURLResponse {
                    print("statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async(execute: {
                        if let dictionary = data as? [String:Any]
                        {
                            if let responseCode = dictionary["success"] as? Bool
                            {
                                if responseCode == true
                                {
                                    //call News APi
                                    self.getNewsListingFromAPI()
                                }else{
                                    //move to select subscription screen
//                                    UtilityClass.showAlertCaption(alertTitle: "Horyaal", alertText: dictionary["msg"] as! String, backgroundColor: UIColor.systemRed)
                                    self.moveToSelectSubscriptionScreen()
                                }
                            }
                        }

                    })
                }
                else {
                    //not authenticate user
                    DispatchQueue.main.async(execute: {
                        print("Move to Login Page After Login..")
                        Constant.kSceneDelegate.switchToLoginVC()
                    })
                }
            }
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func moveToSelectSubscriptionScreen() {
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SelectSubscriptionVC") as? SelectSubscriptionVC
        vc?.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc!, animated: true)
    }

}

extension NewsVC : SWRevealViewControllerDelegate
{
    //MARK:- SWRevealViewControllerDelegate
    func revealController(_ revealController: SWRevealViewController!, willMoveTo position: FrontViewPosition) {
        
        if position == .left
        {
            self.view.endEditing(false)
            self.view.isUserInteractionEnabled = true
            
        }
        else if position == .right
        {
            self.view.endEditing(true)
        }
    }
    
    func revealController(_ revealController: SWRevealViewController, didMoveTo position: FrontViewPosition)
    {
        if position == .right
        {
            //let viewController: UINavigationController? = revealController.frontViewController as! UINavigationController
        }
    }
}

extension NewsVC : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  arrNewsData?.count ?? 0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowHeight : CGFloat = 250.0
        return rowHeight//(70.0 * (self.appDelegate.window?.bounds.size.height)!) / 667.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsCell
        cell.selectionStyle = .none
        let model : NewsDataModel? = arrNewsData?[indexPath.row]
        cell.lblTitle.text = model?.title ?? ""
        cell.lblDate.text = String(format: "%@",(model?.date?.toDates()?.toString() ?? "") as String)
        
        if let imgUrl = model?.thumbnail {
            cell.imgViewIcon.kf.setImage(with: URL(string: imgUrl), placeholder:nil, options: [.transition(.fade(1))], progressBlock: { (a, b) in
                
            }, completionHandler: { (image,error, cacheType, url) in
                
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model : NewsDataModel? = arrNewsData?[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "WebViewVC") as? WebViewVC
        vc!.strTitle = model?.title ?? ""
        vc!.strLoadString = model?.embed ?? ""
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
