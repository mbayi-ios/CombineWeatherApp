
import Foundation
import Combine

protocol WeatherFetchable {
  func weeklyWeatherForecast(forCity city: String) -> AnyPublisher<WeeklyForecastResponse, WeatherError>

  func currentWeatherForecast(forCity city: String) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError>
}

class WeatherFetcher {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
}

extension WeatherFetcher: WeatherFetchable {
  func weeklyWeatherForecast(forCity city: String) -> AnyPublisher<WeeklyForecastResponse, WeatherError> {
    return forecast(with: makeWeeklyForecastComponents(withCity: city))
  }

  func currentWeatherForecast(forCity city: String) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError> {
    return forecast(with: makeCurrentDayForecastComponents(withCity: city))
  }

  private func forecast<T>(with components: URLComponents) -> AnyPublisher<T, WeatherError> where T: Decodable {
    //1
    guard let url = components.url else {
      let error = WeatherError.network(description: "Couldnt create url")
      return Fail(error: error).eraseToAnyPublisher()
    }
    //2
    return session.dataTaskPublisher(for: URLRequest(url: url))
    //3
      .mapError { error in
      .network(description: error.localizedDescription)
      }
    //4
      .flatMap(maxPublishers: .max(1)) { pair in
        decode(pair.data)
      }
    //5
      .eraseToAnyPublisher()
  }


}

// MARK: - OpenWeatherMap API
private extension WeatherFetcher {
  struct OpenWeatherAPI {
    static let scheme = "https"
    static let host = "api.openweathermap.org"
    static let path = "/data/2.5"
    static let key = "552c4d730c6fa42329c1f355129dae3e"
  }
  
  func makeWeeklyForecastComponents(withCity city: String) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/forecast"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
  
  func makeCurrentDayForecastComponents(withCity city: String) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/weather"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
}
