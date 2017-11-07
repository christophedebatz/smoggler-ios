import UIKit
import CoreData
import TransitionButton

 /**
 A chaque démarrage, on envoi toutes les données enregistrées mais non exportées
 A chaque démarrage, on reçoit toutes les données passées
 A chaque fois que l'utilisateur fume, on envoi au serveur ou on sauvegarde en local si pas d'internet
 */

class ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var todayCigarettesCount: UILabel!
    
    // MARK: - Initialize properties
    var managedObjectContext: NSManagedObjectContext?
    let smokingButton = TransitionButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // smoking button job here
        let x = (self.view.frame.size.width - 230) / 2
        let y = (self.view.frame.size.height - 50) / 2
        smokingButton.frame = CGRect(x: x, y: y, width: 230, height: 50)
        smokingButton.backgroundColor = .brown
        smokingButton.setTitle("I'm smoking now", for: .normal)
        smokingButton.cornerRadius = 20
        smokingButton.spinnerColor = .white
        smokingButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        self.view.addSubview(smokingButton)
        
        // display today's cigarettes counter
        self.displayTodaysCigarettes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        todayCigarettesCount.text = text
    }
    
    // MARK: - IBActions
    
    @IBAction func buttonAction(_ button: TransitionButton) {
        self.addSmokingMoment()
    }
}

