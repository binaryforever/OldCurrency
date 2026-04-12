import Foundation

struct FrankfurterResponse: Decodable {
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

    func fetchConversion(from: String, to: String, date: Date, maxTries: Int = 7) async throws -> (rate: Double, actualDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var trialDate = date
        for _ in 0..<maxTries {
            let dateString = formatter.string(from: trialDate)
            let urlString = "https://api.frankfurter.app/\(dateString)?from=\(from)&to=\(to)"
            guard let url = URL(string: urlString) else {
                throw CurrencyServiceError.invalidResponse
            }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw CurrencyServiceError.network
                }
                let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
                if let rate = decoded.rates[to] {
                    return (rate, formatter.date(from: decoded.date) ?? trialDate)
                }
            } catch let error as CurrencyServiceError {
                if case .network = error {
                    throw error
                }
                // For all other errors, try previous day
            } catch {
                // e.g. network or decoding error
                throw CurrencyServiceError.network
            }
            // Subtract one day and try again
            trialDate = Calendar.current.date(byAdding: .day, value: -1, to: trialDate) ?? trialDate
        }
        throw CurrencyServiceError.rateNotFound
    }
}
