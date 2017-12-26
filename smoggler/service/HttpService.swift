import Foundation
import Arrow
import then
import ws

class HttpService {
    
    static let SMOGGLER_API_URI:String = "http://localhost:3000/api"
    
    static func sendUser(user: User, completion: @escaping (_ error: ApiError?, _ result: User?) -> Void) -> Void {
        debugPrint("send User")
        let ws:WS = WS(SMOGGLER_API_URI)
        var model:[String : String] = [String:String]()
        
        if user.email != nil {
            model.updateValue(user.email!, forKey: "email")
        }
        if user.facebookAccessToken != nil {
            model.updateValue(user.facebookAccessToken!, forKey: "fbAccessToken")
        }
        if user.facebookId != nil {
            model.updateValue(user.facebookId!, forKey: "fbId")
        }
        if user.firstName != nil {
            model.updateValue(user.firstName!, forKey: "firstName")
        }
        if user.lastName != nil {
            model.updateValue(user.lastName!, forKey: "lastName")
        }
        if user.pictureUrl != nil {
            model.updateValue(user.pictureUrl!, forKey: "pictureUrl")
        }
        
        ws.post("/users", params: model)
            .then { (json:JSON) in
                print(json)
                let createdUser:User = User()
                createdUser.deserialize(json)
                completion(nil, createdUser)
            }
            .onError { e in
                if let wsError = e as? WSError {
                    print(wsError.status)
                    print(wsError.status.rawValue)
                    completion(ApiError(error: true, code: wsError.status.rawValue), nil)
                } else {
                    completion(ApiError(error: true, code: nil), nil)
                }
                
            }
    }
    
    static func sendCigarettes(cigarettes:[Cigarette], completion: @escaping (_ error: ApiError?) -> Void) -> Void {
        var cigarettesArray:[[String : Any]] = Array()
        for cigarette in cigarettes {
            if (cigarette.smoker == nil) {
                cigarette.smoker = HomeViewController.loggedInUser
            }
            cigarettesArray.append([
                "creationDate": cigarette.creationDate!,
                "sentiment": cigarette.sentiment != nil ? cigarette.sentiment! : nil,
                "coords": [
                    "lat": cigarette.lat,
                    "lng": cigarette.lng
                ]
            ])
        }
        
        let ws:WS = WS(SMOGGLER_API_URI)
        ws.headers = getAuthorizationHeader(user: HomeViewController.loggedInUser!)
        let model = [
            "cigarettes": [cigarettesArray]
        ] as [String : Any]
        print("sending new cigarette")
        ws.post("/me/cigarettes", params: model)
            .then { (json:JSON) in print(json) }
            .onError { e in
                if let wsError = e as? WSError {
                    print(wsError.status)
                    print(wsError.status.rawValue)
                    completion(ApiError(error: true, code: wsError.status.rawValue))
                }
                completion(ApiError(error: true, code: nil))
        }
    }
    
    private static func getAuthorizationHeader(user:User) -> [String : String] {
        return ["Authorization": user.facebookId! + "-" + user.facebookAccessToken!]
    }
    
}
