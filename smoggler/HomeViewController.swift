import UIKit
import CoreData
import CoreLocation
import Alertift
import Smile
import LTMorphingLabel
/**
 A chaque démarrage, on envoi toutes les données enregistrées mais non exportées
 A chaque démarrage, on reçoit toutes les données passées
 A chaque fois que l'utilisateur fume, on envoi au serveur ou on sauvegarde en local si pas d'internet
 */
class HomeViewController : UIViewController, CLLocationManagerDelegate {

    // MARK: - IBOutlets
    @IBOutlet fileprivate var todayCigarettesCount: LTMorphingLabel!
    
    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    var smokingButton:UIButton = UIButton()
    var locationManager: CLLocationManager!
    var coords: CLLocationCoordinate2D! = nil
    var loggedInUser:User?
    
    required init?(coder aDecoder: NSCoder = NSCoder.empty()) {
        super.init(coder: aDecoder)
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        initializeComponents()
    }
    
    func initializeComponents() {
        // smoking button job here
        let x = (self.view.frame.size.width - 230) / 2
        let y = (self.view.frame.size.height - 60) / 2
        
        smokingButton.frame = CGRect(x: x, y: y, width: 230, height: 60)
        smokingButton.backgroundColor = .brown
        smokingButton.setTitle("I'm smoking.", for: .normal)
        smokingButton.layer.borderWidth = 2
        smokingButton.layer.cornerRadius = 10
        smokingButton.addTarget(self, action: #selector(HomeViewController.smoke(_:)), for: .touchUpInside)
        
        view.addSubview(smokingButton)
        displayTodaysCigarettes()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (manager.location != nil) {
            self.coords = manager.location?.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Location manager error = " + error.localizedDescription)
    }
    
    func smoke(becauseOf: String!) -> Void {
        let cigarette:Cigarette = NSEntityDescription.insertNewObject(
                forEntityName: "Cigarette",
                into: self.managedObjectContext!
        ) as! Cigarette
        
        cigarette.smoker = loggedInUser!
        cigarette.creationDate = Date()
    
        if coords != nil {
            cigarette.lat = Double(coords.latitude)
            cigarette.lng = Double(coords.longitude)
        }
        
        if becauseOf != nil {
            cigarette.sentiment = becauseOf!
        }
        
        if ReachabilityManager.shared.isNetworkAvailable {
            HttpService.sendCigarette(cigarette: cigarette)
        } else {
            do {
                try cigarette.managedObjectContext?.save()
                self.displayTodaysCigarettes()
            } catch {
                print("Unexpected error appeared while storing cigarette locally.")
            }
        }
    }
    
    func fetchCigarette() -> [Cigarette] {
        let Cigarette = NSFetchRequest<Cigarette>(entityName: "Cigarette")
        
        do {
            return try (self.managedObjectContext?.fetch(Cigarette))! as [Cigarette]
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
    }
    
    func countTodaysCigarettes() -> Int {
        let startOfDay = NSCalendar.current.startOfDay(for: Date())
        let cigaretteRequest:NSFetchRequest<Cigarette> = Cigarette.fetchRequest()
        cigaretteRequest.predicate = NSPredicate(format: "creationDate > %@", startOfDay as CVarArg)
        
        do {
            return try (self.managedObjectContext?.count(for: cigaretteRequest))! as Int
        } catch {
            fatalError("Failed to fetch cigarettes: \(error)")
        }
    }
    
    func displayTodaysCigarettes() {
        let count = countTodaysCigarettes()
        var plural = ""
        if count > 1 {
            plural = "s"
        }
        
        todayCigarettesCount.text = String(describing: count) + " cigarette" + plural + " today"
    }
    
    // MARK: - IBActions
    @IBAction func smoke(_ sender: UIButton) {
        Alertift.actionSheet(message: "How do you feel right now?")
            .popover(sourceView: self.view, sourceRect: sender.frame)
            .action(.default(Smile.replaceAlias(string: "Happy :grinning:")), handler: {action, index in self.smoke(becauseOf: "happy")})
            .action(.default(Smile.replaceAlias(string: "Drunk :grin:")), handler: {action, index in self.smoke(becauseOf: "drunk")})
            .action(.default(Smile.replaceAlias(string: "Chill :relaxed:")), handler: {action, index in self.smoke(becauseOf: "chilling")})
            .action(.default(Smile.replaceAlias(string: "Nervous :confused:")), handler: {action, index in self.smoke(becauseOf: "nervous")})
            .action(.default(Smile.replaceAlias(string: "Sad :disappointed:")), handler: {action, index in self.smoke(becauseOf: "not-happy")})
            .action(.default(Smile.replaceAlias(string: "Sick :nauseated_face:")), handler: {action, index in self.smoke(becauseOf: "sick")})
            .action(.cancel("Something different..."), handler: { action, index in self.smoke(becauseOf: nil)})
            .show(on: self)
    }
    
}

