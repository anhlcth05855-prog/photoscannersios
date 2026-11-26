import Foundation
#if canImport(UIKit)
import UIKit
#endif

public class CloudAIService {

    public static let shared = CloudAIService()

    private let userDefaults = UserDefaults.standard
    private let endpointKey = "cloud_ai_endpoint_url"
    private let enabledKey = "cloud_ai_enabled"

    public var endpointUrl: String {
        get { userDefaults.string(forKey: endpointKey) ?? "" }
        set { userDefaults.set(newValue, forKey: endpointKey) }
    }

    public var isCloudAiEnabled: Bool {
        get { userDefaults.bool(forKey: enabledKey) && !endpointUrl.isEmpty }
        set { userDefaults.set(newValue, forKey: enabledKey) }
    }

    public func restoreOnCloud(image: UIImage) async -> UIImage? {
        guard isCloudAiEnabled, let url = URL(string: endpointUrl),
              let jpegData = image.jpegData(compressionQuality: 0.88) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"scan.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpegData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                return UIImage(data: data)
            }
        } catch {
            print("Cloud AI error: \(error)")
        }
        return nil
    }
}
