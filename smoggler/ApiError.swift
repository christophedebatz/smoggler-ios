import Foundation

public class ApiError {
    
    private let error:Bool
    
    private let code:Int?
    
    init(error:Bool, code:Int?) {
        self.error = error
        self.code = code
    }
    
    public func hasError() -> Bool {
        return self.error
    }
    
    public func getCode() -> Int? {
        return self.code
    }
    
}
