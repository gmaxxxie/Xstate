enum StatusItemDisplayMode: String {
    case state
    case numeric

    mutating func toggle() {
        self = (self == .state) ? .numeric : .state
    }
}
