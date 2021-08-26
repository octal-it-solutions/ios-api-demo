//
//  WebViewVC.swift
//  Horyaal
//
//  Created by kshitij godara on 25/06/21.
//

import UIKit
import WebKit

class WebViewVC: UIViewController {

    @IBOutlet var webView : WKWebView!
    @IBOutlet var lblNavigationTitle : UILabel!
    var strLoadString : String = ""
    var strTitle : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.isNavigationBarHidden = true
        lblNavigationTitle.text = strTitle
        
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = true
        webView.loadHTMLString(strLoadString, baseURL: nil)
    }
    
    @IBAction func backBtnClicked(sender : UIButton)
    {
        print("backBtnClicked")
        self.navigationController?.popViewController(animated: true)
//        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension WebViewVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
       debugPrint("didCommit")
   }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
       debugPrint("didFinish")
   }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
       debugPrint("didFail")
   }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let urlError = error as? URLError {
            webView.loadHTMLString(urlError.localizedDescription, baseURL: urlError.failingURL)
        } else {
            webView.loadHTMLString(error.localizedDescription, baseURL: URL(string: "data:text/html"))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let exceptions = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: serverTrust));
    }
    

 
}
