struct MessageViewModel: Identifiable, Equatable {
    let id: String
    let content: String
    let username: String
}

struct ProductCardViewModel: Identifiable {
    let id: String
    let description: String
    let imageURL: String
    let name: String
    let unitAmount: Int
    let currency: String
}
