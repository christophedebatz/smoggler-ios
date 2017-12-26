import Foundation
import Arrow

extension Cigarette:ArrowParsable {

    public func deserialize(_ json: JSON) {
        id <-- json["id"]
        sentiment <-- json["sentiment"]
        creationDate <-- json["creationDate"]
        lat <-- json["coords"]!["lat"]
        lng <-- json["coords"]!["lat"]
    }
}
