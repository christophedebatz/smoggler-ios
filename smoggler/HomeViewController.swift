import UIKit
import CoreData
import TransitionButton

/**
 A chaque démarrage, on envoi toutes les données enregistrées mais non exportées
 A chaque démarrage, on reçoit toutes les données passées
 A chaque fois que l'utilisateur fume, on envoi au serveur ou on sauvegarde en local si pas d'internet
 */

class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var todayCigarettesCount: UILabel!
    
    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    var loggedInUser:User?
    let smokingButton = TransitionButton()
    
    required init?(coder aDecoder: NSCoder = NSCoder.empty()) {
        super.init(coder: aDecoder)
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("current user=", self.loggedInUser?.lastName)
        
        // smoking button job here
        let x = (self.view.frame.size.width - 230) / 2
        let y = (self.view.frame.size.height - 60) / 2
        smokingButton.frame = CGRect(x: x, y: y, width: 230, height: 60)
        smokingButton.backgroundColor = .brown
        smokingButton.setTitle("I'm smoking", for: .normal)
        smokingButton.cornerRadius = 20
        smokingButton.spinnerColor = .white
        smokingButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        self.view.addSubview(smokingButton)
        
        // display today's cigarettes counter
        self.displayTodaysCigarettes()
    }
    
    func synchronizeWithServer() {
        
    }
    
    func storeTemporaly() {
        let smokingMoment = NSEntityDescription.insertNewObject(
            forEntityName: "SmokingMoment",
            into: self.managedObjectContext!
            ) as! SmokingMoment
        
        smokingMoment.id = UUID().uuidString
        smokingMoment.date = Date()
        
        do {
            try smokingMoment.managedObjectContext?.save()
            self.displayTodaysCigarettes()
        } catch {
            print("error appeared")
        }
    }
    
    func addSmokingMoment() {
       // send data though network
//        if InternetHelper.isInternetAvailable() {
//            self.synchronizeWithServer()
        
//               let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SmokingMoment")
//               let request = NSBatchDeleteRequest(fetchRequest: fetch)
//               let result = try managedObjectContext?.execute(request)
//        }
        
        // store temporaly data on store
//        else {
            self.storeTemporaly()
//        }
    }

    func fetchSmokingMoments() -> [SmokingMoment] {
        let smokingFetch = NSFetchRequest<SmokingMoment>(entityName: "SmokingMoment")
        
        do {
            return try (self.managedObjectContext?.fetch(smokingFetch))! as [SmokingMoment]
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
    }
    
    func countTodaySmokingMoments() -> Int {
        let startOfDay = NSCalendar.current.startOfDay(for: Date())
        let smokingRequest:NSFetchRequest<SmokingMoment> = SmokingMoment.fetchRequest()
        smokingRequest.predicate = NSPredicate(format: "date > %@", startOfDay as CVarArg)
        
        do {
            return try (self.managedObjectContext?.count(for: smokingRequest))! as Int
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
    }
    
    func displayTodaysCigarettes() {
        let count = self.countTodaySmokingMoments()
        var plural = ""
        if count > 1 {
            plural = "s"
        }
        let text = String(describing: count) + " cigarette" + plural + " today"
        self.todayCigarettesCount.text = text
    }
    
    // MARK: - IBActions
    
    @IBAction func buttonAction(_ button: TransitionButton) {
        self.addSmokingMoment()
    }
}

