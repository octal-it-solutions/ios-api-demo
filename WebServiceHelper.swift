
import UIKit
import Foundation
import SystemConfiguration
import MBProgressHUD


public enum URLType: String
{
	case localURL =   "http://3.108.72.39:2021/v1/api/"
//    case liveURL  = "http://3.108.72.39:2021"
}

class WebServiceHelper: NSObject
{
    
    // MARK: - ActivityIndicator
    public class func startActivityIndicator(_ msg: String?="") {
        
        let hud = MBProgressHUD.showAdded(to: Constant.kSceneDelegate.window!, animated: true)
        hud.mode = MBProgressHUDMode.indeterminate
        if((msg?.count)! > 0) {
            hud.label.text = msg
        }
        
    }
    
    public class func stopActivityIndicator() {
        
        DispatchQueue.main.async(execute: {
            print("Got JSON")
            MBProgressHUD.hide(for: Constant.kSceneDelegate.window!, animated: true)
        });
        
    }
    
    //MARK:- //***** POST Request ***** //
    static func postRequest(method: String, isApplySubscription : String = "true", params: AnyObject, completionHandler: @escaping (_ status: Bool, _ response: AnyObject, _ error: NSError?, _ responseCodes : URLResponse?) -> ())
    {
        
        guard isInternetAvailable()==true else {
            
            
            guard  let rootViewController=(UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }
            
//            guard  let rootViewController=(UIApplication.shared.delegate. as? AppDelegate)?.window?.rootViewController else {
//                return
//            }
            rootViewController.presentAlertWith(message: "Internet connection lost")
            return
        }
        
            // Set up create URL Session
            let session = URLSession.shared
            let endURL  = URLType.localURL.rawValue + method
        
            print("endPointURL ", endURL)
        
           //print json request
            printJsonRequest(params: params)
        
        
            guard let url = URL(string: endURL) else {
                print("Get an error")
                return
            }
        
        var urlRequest = URLRequest(url: url)
        
        if method == Constant.kUpdatePhone {
            urlRequest.httpMethod = "PUT"
        }else{
            urlRequest.httpMethod = "POST"
        }
        
        let loginModel : LoginDataModel? = UtilityClass.getLoginModel()
        let strSelectedLanguage : String = (loginModel?.defaultLanguage == "so") ? "so" : "en"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(strSelectedLanguage, forHTTPHeaderField: "Accept-Language")

		//Add header fields if user is successfully log in
        if let loginModel = UtilityClass.getLoginModel() // If user is log in
        {
            if method != Constant.kTokenRefersh {
                
                urlRequest.setValue(loginModel.token, forHTTPHeaderField: "x-access-token")
                print("--------------> Authorization token in header \(loginModel.token) and user id in header is <---------")
                urlRequest.setValue(isApplySubscription, forHTTPHeaderField: "isApplySubscription")
            }else{
                //token refresh wali api called
            }
            
            urlRequest.setValue(loginModel.token, forHTTPHeaderField: "x-access-token")
            print("--------------> Authorization token in header \(loginModel.token) and user id in header is <---------")
            urlRequest.setValue(isApplySubscription, forHTTPHeaderField: "isApplySubscription")
        }
		
        /*
		//Add version into header
		if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
		{
			urlRequest.setValue(version, forHTTPHeaderField: "AppVersion")
			print("--------------> version  in header \(version) <---------")
		}
 */
        
		urlRequest.timeoutInterval = 120
        
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            } catch {
                print(error.localizedDescription)
            }
        
//			SVProgressHUD.show()
//			SVProgressHUD.setDefaultMaskType(.clear)
        WebServiceHelper.startActivityIndicator()
		
            // **** Make the request **** //
            let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { (data, response, error) in
                
                if let httpResponse = response as? HTTPURLResponse {
                        print("statusCode: \(httpResponse.statusCode)")
                }
				
//				SVProgressHUD.dismiss()
                WebServiceHelper.stopActivityIndicator()
                // make sure we got data
                if data != nil
                {
                    var jsonResult: NSDictionary!
                    jsonResult = nil
                    // parse the result as JSON, since that's what the API provides
                    do {
                        let strData = String(data: data!, encoding: String.Encoding.utf8)
                        print("Data is: ", strData ?? AnyObject.self)
                        
                        jsonResult  = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
						
                        //MARK:-  Parsed received json using helper method
                        DispatchQueue.main.async(execute: {
                            print("Got JSON")
//                            WebServiceHelper.jsonParsing(jsonResult: jsonResult, completionHandler: completionHandler)
                            if method != Constant.kTokenRefersh {
                                WebServiceHelper.jsonParsing(jsonResult: jsonResult, responseCodes: response, completionHandler: completionHandler)
                            }else{
                                WebServiceHelper.jsonParsing(apiname : Constant.kTokenRefersh ,jsonResult: jsonResult, responseCodes: response, completionHandler: completionHandler)
                            }
                            

                        });
                        
						
                    } catch {
                        // Oops! ;)
                        print("error trying to convert data to JSON")
                        return
                    }
                    if jsonResult == nil
					{
                        DispatchQueue.main.async(execute: {
                            print("Got JSON")
                            completionHandler(false, jsonResult, error as NSError?, response)

                        });
                    }
                }else {
                    print("Something went wrong")
                }
            })
            task.resume()
        
        
    }
    
//    static func jsonParsing(jsonResult: NSDictionary?, completionHandler: @escaping (_ status: Bool, _ response: AnyObject, _ error: NSError?) -> ())
//    {
    static func jsonParsing(apiname : String = Constant.kLOGIN ,jsonResult: NSDictionary?, responseCodes : URLResponse? , completionHandler: @escaping (_ status: Bool, _ response: AnyObject, _ error: NSError?, _ responseCodes : URLResponse?) -> ())
    {
//        if let httpResponse = responseCodes as? HTTPURLResponse {
//            if httpResponse.statusCode == 403 {
//                //TOKEN_EXPIRED
//                Constant.kSceneDelegate.switchToLoginVC()
//            }else{
//
//            }
//        }
        if let jsonResult = jsonResult
        {
//            DispatchQueue.main.async(execute: {
//
//                completionHandler(true, jsonResult, nil,responseCodes)
//
//            });
            if let responseCode = jsonResult["success"] as? Bool
            {
                if responseCode == true
                {
                    DispatchQueue.main.async(execute: {

                        completionHandler(true, jsonResult, nil,responseCodes)

                    });

                }
                else if responseCode == false
                {
                    DispatchQueue.main.async(execute: {

                        if apiname == Constant.kTokenRefersh {
                            completionHandler(false, jsonResult, nil,responseCodes)
                        }
                        else {
                            guard let errorMsg = jsonResult["msg"] as? String else{ return }

                            DispatchQueue.main.async(execute: {
                                
                                if let httpResponse = responseCodes as? HTTPURLResponse {
                                    if httpResponse.statusCode == 200 {
                                        //TOKEN_EXPIRED
                                        UtilityClass.showAlert(alertTitle: "Horyaal", alertText: errorMsg, validationErrorObj: UILabel())
                                    }else{
                                        completionHandler(true, jsonResult, nil,responseCodes)
                                    }
                                }

//                                UtilityClass.showAlert(alertTitle: "Horyaal", alertText: errorMsg, validationErrorObj: UILabel())
//                                completionHandler(true, jsonResult, nil,responseCodes)
                            })
                        }
                    });
                }
            }
        }
    }
    
    //MARK:- //***** GET Request *****//
    static func getRequest(method: String, isApplySubscription : String = "true", params: AnyObject, completionHandler: @escaping (_ status: Bool, _ response: AnyObject?, _ error: NSError?, _ responseCodes : URLResponse?) -> ())
    {
        
        guard isInternetAvailable()==true else {
            
            guard  let rootViewController=(UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }
            rootViewController.presentAlertWith(message: "Internet connection lost")
            return
        }
        
        guard let dictionary=params as? NSDictionary else {
            
            guard  let rootViewController=(UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }
            rootViewController.presentAlertWith(message: "Parameter is not NSDictionary")
            return
        }
        
        var baseUrl = ""
        
        if method == Constant.kNewsAPI {
            baseUrl = method
        }else{
            baseUrl =  URLType.localURL.rawValue+method+"?"
            for (key, value) in dictionary
            {
                print("key: \(key)")
                print("value= \(value)")
                baseUrl=baseUrl+"\(key)=\(value)&"
            }
            
            baseUrl=baseUrl.substring(to: baseUrl.index(before: baseUrl.endIndex))
            baseUrl=baseUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        }
        
        print(baseUrl)
        let url = NSURL(string: baseUrl)
        
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "GET"
        
        if method == Constant.kNewsAPI {
            //specially for news api
            request.setValue("516cbdda97msh641255a08526d4dp1433b1jsn199165cbf82d", forHTTPHeaderField: "x-rapidapi-key")
        }
        
        let loginModel : LoginDataModel? = UtilityClass.getLoginModel()
        let strSelectedLanguage : String = (loginModel?.defaultLanguage == "so") ? "so" : "en"
        
        request.setValue(strSelectedLanguage, forHTTPHeaderField: "Accept-Language")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let loginModel = UtilityClass.getLoginModel() // If user is log in
        {
            
            request.setValue(loginModel.token, forHTTPHeaderField: "x-access-token")
            print("--------------> Authorization token in header \(loginModel.token) and user id in header is <---------")
            request.setValue(isApplySubscription, forHTTPHeaderField: "isApplySubscription")
        }
        
        
        request.timeoutInterval = 120;
        
        let err : NSError?
        err = nil
        
        //print json request
        self.printJsonRequest(params: dictionary)
        WebServiceHelper.startActivityIndicator()
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            let error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            if data != nil{
                var jsonResult: NSDictionary!
                jsonResult = nil
                
                WebServiceHelper.stopActivityIndicator()
                
                do {
                    let json = NSString(data: data! as Data, encoding: String.Encoding.utf8.rawValue)! as String
                    NSLog(String(data: data!, encoding: String.Encoding.utf8)!)
                    print("*********** json request ---->>>>>>> \(json)")
                    if method == Constant.kNewsAPI {
                        let arrResponse = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSArray
                        let yourMutableDictionary = NSMutableDictionary()
                        yourMutableDictionary.setObject(arrResponse, forKey: "Results" as NSCopying)
                        jsonResult = yourMutableDictionary.copy() as? NSDictionary
                    }else{
                        jsonResult = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                    }
                    
                    print(jsonResult)
                } catch _ {
                }
                
                if jsonResult == nil{
                    DispatchQueue.main.async{
                        completionHandler(false, jsonResult, err, response)
                    }
                }
                else if (jsonResult != nil) {
                    DispatchQueue.main.async{
                        completionHandler(true, jsonResult, nil, response)
                    }
                }
            }
            else if error != nil{
                DispatchQueue.main.async{
                    completionHandler(false, nil, err, response)
                }
            }
            else{
                DispatchQueue.main.async{
                    completionHandler(false, nil, err, response)
                }
            }
            
        }
        task.resume()
        
        
    }
    
    //MARK:- //***** MULTI-PART Request ***** //
    static func multiPartMedia(method: String, isApplySubscription : String = "true", _ image : UIImage, params : NSDictionary , completeBlock:@escaping (_ status : Bool, _ data : AnyObject?, _ error : NSError?, _ responseCodes : URLResponse?)->())
    {
        guard isInternetAvailable()==true else {
            
            guard  let rootViewController=(UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }
            rootViewController.presentAlertWith(message: "Internet connection lost")
            return
        }
            
            let boundary = generateBoundaryString()
        let data = image.jpegData(compressionQuality: 0.5)
            
            let dictImage = NSMutableDictionary()
            dictImage.setObject("image", forKey: "filename" as NSCopying)
            dictImage.setObject(data! , forKey: "fileData" as NSCopying)
            
            let arrImageData = NSArray(object: dictImage)
            
            let bodyData = createBodyWithParameters(params as? [String : AnyObject], filePathKey: "filename", files: arrImageData as! Array<Dictionary<String, AnyObject>>, boundary: boundary)
        
            // Set up create URL session
            let session = URLSession.shared
            let endURL  = URLType.localURL.rawValue + method
            print("endPointURL ", endURL)
        
            //print json request
            printJsonRequest(params: params)
//            print("params ", params)
        
            guard let url = URL(string: endURL) else {
                print("Get an error")
                return
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
		
        //urlRequest.addValue("8bit", forHTTPHeaderField: "Content-Transfer-Encoding")
        urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		
		//MARK:- Header field for Duckling app only
        let loginModel : LoginDataModel? = UtilityClass.getLoginModel()
        let strSelectedLanguage : String = (loginModel?.defaultLanguage == "so") ? "so" : "en"
        
        urlRequest.setValue(strSelectedLanguage, forHTTPHeaderField: "Accept-Language")
        
        //Add header fields if user is successfully log in
        if let loginModel = UtilityClass.getLoginModel() // If user is log in
        {
            
            urlRequest.setValue(loginModel.token, forHTTPHeaderField: "x-access-token")
            print("--------------> Authorization token in header \(loginModel.token) and user id in header is <---------")
            urlRequest.setValue(isApplySubscription, forHTTPHeaderField: "isApplySubscription")
        }
            urlRequest.httpBody = bodyData
            urlRequest.timeoutInterval = 220
            do {
                //urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            } catch {
                print(error.localizedDescription)
            }
            
            var err : NSError?
            err = nil
        
        WebServiceHelper.startActivityIndicator()
        
            let dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                // Handle response
                
                WebServiceHelper.stopActivityIndicator()
                
                let error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
                if data != nil {
                    
                    var jsonResult: NSDictionary!
                    jsonResult = nil
                    
                    do {
                        jsonResult = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                    } catch _ {
                    }
                    
                    printJsonRequest(params: jsonResult)
                    if jsonResult == nil {
                        completeBlock(false, jsonResult, err, response)
                    }
                    else if (jsonResult != nil) {
                        completeBlock(true, jsonResult, nil, response)
                    }
                }
                else if error != nil {
                    completeBlock(false, nil, err, response)
                }else {
                    completeBlock(false, nil, err, response)
                }
            })
            dataTask.resume()
        
    }
	
    static func uploadVideo(serviceName:String , videoData : NSData, parameter : NSDictionary,controller : AnyObject , completeBlock:@escaping (_ status : Bool, _ data : AnyObject?, _ error : NSError?, _ responseCodes : URLResponse?)->())
	{
		
		guard isInternetAvailable()==true else {
			
            guard  let rootViewController=(UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }
			rootViewController.presentAlertWith(message: "Internet connection lost")
			return
		}
		
		let endURL  = URLType.localURL.rawValue + serviceName
		print("endPointURL ", endURL)
		
		//print request in json format
		printJsonRequest(params: parameter)
		
		guard let url = URL(string: endURL) else {
			print("Get an error")
			return
		}
		
        WebServiceHelper.startActivityIndicator()
		
		let boundary = generateBoundaryString()
		
		let dictVideo = NSMutableDictionary()
		dictVideo.setObject(videoData , forKey: "fileData" as NSCopying)
		dictVideo.setObject("ClaimVideo", forKey: "filename"  as NSCopying)
		let arrVideoData = NSArray(object: dictVideo)
		
		
		let session = URLSession.shared
		let urlRequest = NSMutableURLRequest(url: url)
		
		
		
		print(urlRequest.url?.absoluteString ?? "")
		
		// request.addValue("8bit", forHTTPHeaderField: "Content-Transfer-Encoding")
		//        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
                urlRequest.addValue("video/mp4", forHTTPHeaderField: "Content-Type")
//                urlRequest.addValue("\(bodyData.length)", forHTTPHeaderField: "Content-Length")
		
		//MARK:- Header field for Duckling app only
        let loginModel : LoginDataModel? = UtilityClass.getLoginModel()
        let strSelectedLanguage : String = (loginModel?.defaultLanguage == "so") ? "so" : "en"
        
        urlRequest.setValue(strSelectedLanguage, forHTTPHeaderField: "Accept-Language")
        
		/*
        if let loginModel = UtilityClass.getLoginModel() // If user is log in
        {
            
            urlRequest.setValue(loginModel.authorizationToken, forHTTPHeaderField: "AuthorizationToken")
            print("--------------> Authorization token in header \(loginModel.authorizationToken) and user id in header is \(loginModel.userId.description) <---------")
            urlRequest.setValue(loginModel.userDetailsId.description, forHTTPHeaderField: "UserId")
            urlRequest.setValue("\(loginModel.userType!)", forHTTPHeaderField: "UserType")
        }
		*/
		
		urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		
		
		let bodyData = createBodyWithParameters(parameter as? [String : AnyObject], filePathKey: "filename", files: arrVideoData as! Array<Dictionary<String, AnyObject>>, boundary: boundary)
		
		
		urlRequest.httpMethod = "POST"
		urlRequest.timeoutInterval = 250
		
		var error: NSError?
		urlRequest.httpBody = bodyData as Data
		
		if let error = error {
			print("\(error.localizedDescription)")
		}
		
		var err : NSError?
		
		
		let dataTask = session.dataTask(with: urlRequest as URLRequest) { data, response, error in
			
			print(error?.localizedDescription)
			
            WebServiceHelper.stopActivityIndicator()
			// Handle response
			let error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
			if data != nil
			{
				print(String(data: data!, encoding: .utf8)!)
				var jsonResult: NSDictionary!
				jsonResult = nil
				
				do{
					jsonResult = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
					print(jsonResult)
					
					//MARK:-  Parsed received json using helper method
//					WebServiceHelper.jsonParsing(jsonResult: jsonResult, completionHandler: completeBlock)
                    WebServiceHelper.jsonParsing(jsonResult: jsonResult, responseCodes: response, completionHandler: completeBlock)
					
				} catch _ {
				}
				if jsonResult == nil{
					DispatchQueue.main.async{
						completeBlock(false, jsonResult, err, response)
					}
				}
				
			}
			else if error != nil{
				DispatchQueue.main.async{
					completeBlock(false, nil, err, response)
				}
			}
			else{
				DispatchQueue.main.async{
					completeBlock(false, nil, err, response)
				}
			}
			
		}
		dataTask.resume()
	}
	
    //MARK:- //******* Create MultiPart Body ********** //
    class func createBodyWithParameters(_ parameters: [String: AnyObject]?, filePathKey: String?, files : Array<Dictionary<String, AnyObject>>, boundary: String) -> Data
    {
        
        let body : NSMutableData = NSMutableData();
		
		
        if parameters != nil {
            for (key, value) in parameters! {
                body.append(("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
            }
        }
		
		let json = NSString(data: body as Data , encoding: String.Encoding.utf8.rawValue)! as String
		print("*********** Body request ---->>>>>>> \(json)")
        
        
        for file in files {
            let filename : String = file["filename"] as! String
            let fileData : Data = file["fileData"] as! Data
            
            body.append(("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(filename)\"; filename=\"\(filename)\"\r\n\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
            body.append(fileData)
            body.append(("\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        }
 
        body.append(("--\(boundary)--\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        return body as Data
    }
    
    class func generateBoundaryString() -> String {
        return "************"
    }
    
    //MARK:- //***** Print json request ***** //
    class func printJsonRequest(params:AnyObject)
    {
        do {
            if let postData : NSData = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData?{
                
                let json = NSString(data: postData as Data, encoding: String.Encoding.utf8.rawValue)! as String
                print("*********** json request ---->>>>>>> \(json)")
                
            }
            
        }
        catch {
            print(error)
        }
    }
	
    //MARK:- //***** Check Internet ***** //
    class func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    

}
