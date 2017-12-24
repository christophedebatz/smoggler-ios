import Foundation
import CoreData
import FacebookCore
import FacebookLogin
import Alertift

class LoginViewController: UIViewController {

    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func showFacebookConnect() {
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email ])
        loginButton.center = view.center
        self.view.addSubview(loginButton)
    }
    
    func gotoMainView(user:User?) {
        DispatchQueue.main.async {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController:UITabBarController = storyBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
            let homeViewController:HomeViewController = nextViewController.viewControllers![0] as! HomeViewController
            homeViewController.loggedInUser = user
            self.present(nextViewController, animated:true, completion:nil)
        }
    }
    
    func storeNewLoggedInUser(user:User?) {
        if user != nil {
            do {
                try user?.managedObjectContext?.save()
            } catch {
                print("Error appeared while storing logged in user on cache.")
            }
        }
    }
    
    func fetchCurrentLoggedInUser(apiId:String) -> User? {
        let userRequest:NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "facebookId = %@", apiId as CVarArg)
        
        do {
            let users = try (self.managedObjectContext?.fetch(userRequest))! as [User]
            if users.count > 0 {
                return users[0]
            }
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
        return nil
    }
    
    func fetchHttpFacebookUser(completion: @escaping (_ error: Bool, _ result: User?) -> Void) {
        let connection = GraphRequestConnection()
        let request = GraphRequest(
            graphPath: "me",
            parameters: ["fields": "first_name, last_name, email"],
            accessToken: AccessToken.current,
            httpMethod: GraphRequestHTTPMethod.GET,
            apiVersion: "2.11"
        )
        
        request.start { (response, result) in
            switch result {
            case .failed(let error):
                print("Error when querying facebook profile \(error)")
                completion(true, nil)
                
            case .success(let response):
                let user:User = NSEntityDescription.insertNewObject(
                    forEntityName: "User",
                    into: self.managedObjectContext!
                    ) as! User
                
                if let dict = response.dictionaryValue {
                    let email = dict["email"] as? String
                    let firstName = dict["first_name"] as? String
                    let lastName = dict["last_name"] as? String
                    if let picture = dict["picture"] as? NSDictionary {
                        if let data = picture["data"] as? NSDictionary{
                            if let profilePicture = data["url"] as? String {
                                user.pictureUrl = profilePicture
                            }
                        }
                    }
                    
                    user.email = email
                    user.firstName = firstName
                    user.lastName = lastName
                    user.facebookId = AccessToken.current?.userId
                    user.facebookAccessToken = AccessToken.current?.authenticationToken
                    user.facebookAccessTokenExpirationDate = AccessToken.current?.expirationDate
                }
                
                completion(false, user)
            }
        }
        connection.add(request)
        connection.start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel()
        label.center = CGPoint(x: 0, y: view.frame.size.height / 2)
        label.frame.size = CGSize(width: 500, height: 200)
        label.textColor = .red
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        
        if let accessToken = AccessToken.current {
            if accessToken.userId == nil {
                showFacebookConnect()
            } else {
                let user:User? = fetchCurrentLoggedInUser(apiId: accessToken.userId!)
                if user != nil {
                    if !ReachabilityManager.shared.isNetworkAvailable {
                        label.text = "You are not connected to the Internet now."
                    } else {
                        self.fetchHttpFacebookUser(completion: { (error: Bool, facebookUser: User?) -> Void in
                            if (error == false && facebookUser != nil) {
                                HttpService.sendUser(user: facebookUser!, completion: { (error: ApiError?, remoteUser: User?) -> Void in
                                    if error != nil && remoteUser != nil {
                                        self.storeNewLoggedInUser(user: remoteUser)
                                        self.gotoMainView(user:remoteUser)
                                    } else {
                                        if error?.getCode() == 409 {
                                            self.gotoMainView(user:facebookUser!)
                                        } else {
                                            label.text = "An error occured while storing user remotly. Please try again."
                                        }
                                    }
                                })
                            } else {
                                label.text = "An error occured while exchanging data whith Facebook. Please try again."
                            }
                        })
                    }
                } else {
                    self.gotoMainView(user:user)
                }
            }
        } else {
            self.showFacebookConnect()
        }
        
        if label.text != nil {
            self.view.addSubview(label)
        }
    }

}
