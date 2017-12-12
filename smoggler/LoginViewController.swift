import Foundation
import CoreData
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {

    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let accessToken = AccessToken.current {
            if accessToken.userId == nil {
                self.showFacebookConnect()
            } else {
                let user:User? = self.fetchCurrentLoggedInUser(apiId: accessToken.userId!)
                if user == nil {
                    self.fetchHttpFacebookUser(completion: { (error: Bool, responseUser: User?) -> Void in
                        if error == false {
                            self.storeNewLoggedInUser(user: responseUser)
                            self.gotoMainView(user:responseUser)
                        } else {
                            // show alert dialog to ask user retrying process
                        }
                    })
                } else {
                    self.gotoMainView(user:user)
                }
            }
        } else {
            self.showFacebookConnect()
        }
    }
    
    func showFacebookConnect() {
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
        loginButton.center = view.center
        self.view.addSubview(loginButton)
    }
    
    func gotoMainView(user:User?) {
        if user != nil {
            DispatchQueue.main.async {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController:UITabBarController = storyBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                let homeViewController = nextViewController.viewControllers![0] as! HomeViewController
                homeViewController.loggedInUser = user
                self.present(nextViewController, animated:true, completion:nil)
            }
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
//                        let locale = dict["locale"] as? String
                        
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
//                        user.locale = locale
                        user.facebookId = AccessToken.current?.userId
                        user.facebookAccessToken = AccessToken.current?.authenticationToken
                        user.facebookAccessTokenExpirationDate = AccessToken.current?.expirationDate
                    }
//                    user.birthday = response.dictionaryValue?["birthday"] as? String
//                    user.gender = Int16((response.dictionaryValue?["gender"] as! String))!
//                    user.locale = response.dictionaryValue?["locale"] as? String
                    
                    completion(false, user)
            }
        }
        connection.add(request)
        connection.start()
    }

}
