import Foundation
import Arrow

extension User:ArrowParsable {
    
    public func deserialize(_ json: JSON) {
        id <-- json["id"]
        facebookAccessToken <-- json["fbAccessToken"]
        facebookId <-- json["fbId"]
        firstName <-- json["firstName"]
        lastName <-- json["lastName"]
        pictureUrl <-- json["pictureUrl"]
        email <-- json["email"]
        role <-- json["role"]
        creationDate <-- json["creationDate"]
        updateDate <-- json["updateDate"]
    }
}
