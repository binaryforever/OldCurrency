import Foundation

struct FranfurterResponse: Decodable {
    let rates: [String: Double]
    let date: String
}

enum CurrencyServiceError: Error, LocalizedError {
    case network
    case invalidResponse
    case rateNotFound

    var errorDescription: String? {
        switch self {
        case .network: return "Network error."
        case .invalidResponse: return "Malformed or missing data."
        case .rateNotFound: return "Conversion rate not found."
        }
    }
}

class CurrencyService {
    static let shared = CurrencyService()

    private init() {}

    /// Fetches the historical conversion rate between two currencies on a given date.
    func fetchConversion(from: String, to: String, date: Date) async throws -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // Franfurter API docs: https://www.frankfurter.app/docs/
        let urlString = "https://api.frankfurter.app/\(dateString)?from=\(from)&to=\(to)"
        guard let url = URL(string: urlString) else {
            throw CurrencyServiceError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CurrencyServiceError.network
        }

        let decoded = try JSONDecoder().decode(FranfurterResponse.self, from: data)
        guard let rate = decoded.rates[to] else {
            throw CurrencyServiceError.rateNotFound
        }
        return rate
    }
}
