import UIKit
import CommonEffects
import Stopwatch
import GitHub
import GameOfLife

public struct HomeEnvironment
{
    let getDate: () -> Date
    let timer: (TimeInterval) -> AsyncStream<Date>
    let fetchRequest: (URLRequest) async throws -> Data

    let gameOfLife: GameOfLife.Root.Environment
}

// MARK: - Live Environment

extension HomeEnvironment
{
    public static var live: HomeEnvironment
    {
        HomeEnvironment(
            getDate: { Date() },
            timer: { timeInterval in
                Timer.publish(every: timeInterval, tolerance: timeInterval * 0.1, on: .main, in: .common)
                    .autoconnect()
                    .toAsyncStream()

                // Warning: Using `Task.sleep` may not be accurate timer.
//                AsyncStream { continuation in
//                    let task = Task {
//                        while true {
//                            if Task.isCancelled { break }
//                            await Task.sleep(UInt64(timeInterval * 1_000_000_000))
//                            continuation.yield(Date())
//                        }
//                        continuation.finish()
//                    }
//                    continuation.onTermination = { @Sendable _ in
//                        task.cancel()
//                    }
//                }
            },
            fetchRequest: { urlRequest in
                try await CommonEffects.fetchData(for: urlRequest, delegate: nil)
            },
            gameOfLife: .live
        )
    }
}

extension HomeEnvironment
{
    var github: GitHub.Environment
    {
        GitHub.Environment(
            fetchRepositories: { searchText in
                var urlComponents = URLComponents(string: "https://api.github.com/search/repositories")!
                urlComponents.queryItems = [
                    URLQueryItem(name: "q", value: searchText)
                ]

                var urlRequest = URLRequest(url: urlComponents.url!)
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                let data = try await self.fetchRequest(urlRequest)
                let response = try decoder.decode(SearchRepositoryResponse.self, from: data)
                return response
            },
            fetchImage: { url in
                let urlRequest = URLRequest(url: url)
                guard let data = try? await self.fetchRequest(urlRequest) else {
                    return nil
                }
                return UIImage(data: data)
            },
            searchRequestDelay: 0.3,
            imageLoadMaxConcurrency: 3
        )
    }

    var stopwatch: Stopwatch.Environment
    {
        Stopwatch.Environment(
            getDate: getDate,
            timer: timer
        )
    }
}
