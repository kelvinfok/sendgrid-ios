//
//  ViewController.swift
//  sendgrid-youtube-ios
//
//  Created by Kelvin Fok on 17/7/22.
//

import UIKit
import Combine

class ViewController: UIViewController {
  
  // https://stackoverflow.com/questions/50781508/sendgrid-api-request-in-swift-with-urlsession
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var statusLabel: UILabel!
  
  private let emailService = EmailService()
  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.isHidden = true
  }
    
  @IBAction func sendEmailButtonTapped() {
    statusLabel.isHidden = true
    guard let text = textView.text, !text.isEmpty else { return }
    
    emailService.send(message: text)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        self?.statusLabel.isHidden = false
        if case .failure(let error) = completion {
          self?.statusLabel.text = error.localizedDescription
        }
      } receiveValue: { [weak self] isSuccessful in
        self?.statusLabel.text = isSuccessful ? "Sent successfully 👍🏻" : "Something went wrong! 😭"
      }.store(in: &cancellables)
  }

}

class EmailService {
  
  func send(message: String) -> AnyPublisher<Bool, Error> {
        
    let data: Data = {
      let email = "kelmobot@gmail.com"
      let json: [String: Any] = [
        "personalizations":[["to": [["email": email]]]],
        "from": ["email": email],
        "subject": message.prefix(20),
        "content":[["type":"text/plain", "value": message]]
      ]
      return try! JSONSerialization.data(withJSONObject: json, options: [])
    }()
    
    let request: URLRequest = {
      let apiKey = "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"
      let url = URL(string: "https://api.sendgrid.com/v3/mail/send")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = data
      return request
    }()
    
    return URLSession.shared.dataTaskPublisher(for: request)
      .catch { error in
        return Fail(error: error).eraseToAnyPublisher()
      }.tryMap { output in
        let statusCode = (output.response as? HTTPURLResponse)?.statusCode ?? 0
        return (200...299).contains(statusCode)
      }.eraseToAnyPublisher()
  }
}
