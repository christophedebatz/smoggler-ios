import UIKit
import CoreData
import CoreLocation
import Alertift
import Smile
import LTMorphingLabel

class HomeViewController : UIViewController, CLLocationManagerDelegate {

    // MARK: - IBOutlets
    @IBOutlet fileprivate var todayCigarettesCount: LTMorphingLabel!
    @IBOutlet weak var headline: UILabel!
    @IBOutlet weak var waitingIndicator: UIActivityIndicatorView!
    
    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    var smokingButton:UIButton = UIButton()
    var locationManager: CLLocationManager!
    var coords: CLLocationCoordinate2D! = nil
    public static var loggedInUser:User?
    
    required init?(coder aDecoder: NSCoder = NSCoder.empty()) {
        super.init(coder: aDecoder)
        let appDelegate:AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
        appDelegate.homeViewController = self
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        initializeComponents()
    }
    
    func initializeComponents() {
        if HomeViewController.loggedInUser != nil {
            self.headline.text = "Hello " + (HomeViewController.loggedInUser!.firstName?.capitalized)!
        } else {
            self.headline.text = "Hello :)"
        }
        self.view.addSubview(self.headline)
        
        // smoking button job here
        let x = (self.view.frame.size.width - 230) / 2
        let y = (self.view.frame.size.height - 60) / 2
        
        smokingButton.frame = CGRect(x: x, y: y, width: 230, height: 60)
        smokingButton.backgroundColor = .brown
        smokingButton.setTitle("I'm smoking.", for: .normal)
        smokingButton.layer.borderWidth = 2
        smokingButton.layer.cornerRadius = 10
        smokingButton.addTarget(self, action: #selector(HomeViewController.smoke(_:)), for: .touchUpInside)
        
        waitingIndicator.layer.isHidden = true
        self.view.addSubview(smokingButton)
        self.refreshCigaretteTodayCount()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if manager.location != nil {
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
        
        cigarette.smoker = HomeViewController.loggedInUser!
        cigarette.creationDate = Date()
    
        if coords != nil {
            cigarette.lat = Double(coords.latitude)
            cigarette.lng = Double(coords.longitude)
        }
        
        if becauseOf != nil {
            cigarette.sentiment = becauseOf!
        }
        
        if ReachabilityManager.shared.isNetworkAvailable {
            waitingIndicator.layer.isHidden = false
            waitingIndicator.startAnimating()
            HttpService.sendCigarettes(cigarettes: [cigarette], completion: { (error: ApiError?) -> Void in
                self.waitingIndicator.stopAnimating()
                self.waitingIndicator.layer.isHidden = true
                if error != nil {
                    // display error
                } else {
                    self.addCigaretteCount()
                    let localService = LocalStorageService(managedObjectContext: self.managedObjectContext!)
                    localService.removeAllCigarettes()
                    self.refreshCigaretteTodayCount()
                }
            })
        } else {
            do {
                try cigarette.managedObjectContext?.save()
                self.addCigaretteCount()
                self.refreshCigaretteTodayCount()
                print("saved locally")
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
            fatalError("Failed to fetch cigarettes: \(error)")
        }
    }
    
    func addCigaretteCount() -> Void {
        let startOfDay = NSCalendar.current.startOfDay(for: Date())
        
        // all daily metric of today
        let dailyMetricsRequest:NSFetchRequest<DailyMetric> = DailyMetric.fetchRequest()
        dailyMetricsRequest.predicate = NSPredicate(format: "date > %@", startOfDay as CVarArg)
        
        // execute get request
        var dailyMetrics:[DailyMetric] = []
        do {
            dailyMetrics = try (self.managedObjectContext?.fetch(dailyMetricsRequest))! as [DailyMetric]
        } catch {
            fatalError("Failed to fetch cigarettes: \(error)")
        }
        
        // if one already exists for today, just update it
        if dailyMetrics.count == 1 {
            let metric = dailyMetrics[0]
            metric.setValue(Date(), forKey: "date")
            metric.setValue(metric.count + 1, forKey: "count")
        }
        
        // if no metrics for today, create a new one
        else if dailyMetrics.count == 0 {
            let dailyMetric:DailyMetric = NSEntityDescription.insertNewObject(
                forEntityName: "DailyMetric",
                into: self.managedObjectContext!
                ) as! DailyMetric
            
            dailyMetric.count = 1
            dailyMetric.date = Date()
        } else {
            print("error because today's metrics count is more than one.")
        }
        
        // store locally
        do {
            try self.managedObjectContext?.save()
            print("saving one cigarette on local counter")
        } catch {
            print("Unexpected error appeared while adding to local counter.")
        }
    }
    
    func countTodaysCigarettes() -> Int {
        let startOfDay = NSCalendar.current.startOfDay(for: Date())
        
        // all daily metric of today
        let dailyMetricsRequest:NSFetchRequest<DailyMetric> = DailyMetric.fetchRequest()
        dailyMetricsRequest.predicate = NSPredicate(format: "date > %@", startOfDay as CVarArg)
        
        // execute get request
        var dailyMetrics:[DailyMetric] = []
        do {
            dailyMetrics = try (self.managedObjectContext?.fetch(dailyMetricsRequest))! as [DailyMetric]
        } catch {
            fatalError("Failed to fetch cigarettes: \(error)")
        }
        
        return dailyMetrics.count == 1 ? Int(dailyMetrics[0].count) : 0
    }
    
    func refreshCigaretteTodayCount() {
        let count = self.countTodaysCigarettes()
        var plural = ""
        if count > 1 {
            plural = "s"
        }
        self.todayCigarettesCount.text = String(describing: count) + " cigarette" + plural + " today"
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
            .action(.default("Something different..."), handler: { action, index in self.smoke(becauseOf: "NA")})
            .action(.cancel("Cancel"))
            .show(on: self)
    }
    
}

