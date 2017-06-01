import JSON

extension JSON {
    public func permit(_ keys: [String]) -> JSON {
        guard var object = self.object else { return self }

        object.forEach { key,_ in
            if(!keys.contains(key)) {
                object[key] = nil
            }
        }
        
        return JSON(Node.object(object))
    }
}
