
import Foundation
class APICaller {
    static let  shared = APICaller()

    static let allStatesUrl = URL(string: "https://api.covidtracking.com/v2/states.json")

    enum DataScore {
        case national
        case state(State)
    }

    public func getCovidData(for scope: DataScore,completion: @escaping (Result<[DayData], Error>) -> Void) {
        let urlString: String
        switch scope {
        case .national:
            urlString =  "https://api.covidtracking.com/v2/us/daily.json"
        case .state(let state):
            urlString =  "https://api.covidtracking.com/v2/states/\(state.state_code.lowercased())/daily.json"
        }

        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, _, error  in
            guard let data = data, error == nil else { return }

            do {
                let result = try JSONDecoder().decode(CovidDataResponse.self, from: data)

                let models: [DayData] = result.data.compactMap {
                    guard let value = $0.cases?.total.value,
                          let date = DateFormatter.dayFormatter.date(from: $0.date) else {
                              return nil
                          }
                    return DayData(
                        date: date,
                        count: value
                    )
                }
                completion(.success(models))

            }
            catch {
                completion(.failure(error))
            }
        }
        task.resume()

    }
    public func getStateList(completion: @escaping (Result<[State], Error>) -> Void
    ) {
        guard let url = APICaller.allStatesUrl else { return }
        URLSession.shared.dataTask(with: url) { data, _, error  in
            guard let data = data, error == nil else { return }

            do {
                let result = try JSONDecoder().decode(StateListResponse.self, from: data)
                let states = result.data
                completion(.success(states))
            }
            catch {
                completion(.failure(error))
            }
        }.resume()
    }
}



struct StateListResponse: Codable {
    let data: [State]
}

struct State: Codable {
    let name: String
    let state_code: String

}
struct CovidDataResponse: Codable {
    let data: [CovidDayData]
}
struct CovidDayData: Codable {
    let cases: CovidCases?
    let date: String
}
struct CovidCases: Codable {
    let total: TotalCases
}
struct TotalCases: Codable {
    let value:  Int?
}
struct DayData {
    let date: Date
    let count: Int
}


extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD"
        return formatter
    }()

    static let prettyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
