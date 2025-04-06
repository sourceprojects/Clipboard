import Foundation

class VersionChecker {
    static let shared = VersionChecker()
    
    private let versionURL = URL(string: "https://raw.githubusercontent.com/alvin-ictn/ClipJoy/main/version.json")!
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    func checkForUpdates(completion: @escaping (Bool, String?, String?) -> Void) {
        print("Starting version check...")
        print("Current version: \(currentVersion)")
        print("Checking URL: \(versionURL)")
        
        let task = URLSession.shared.dataTask(with: versionURL) { data, response, error in
            if let error = error {
                print("Error checking for updates: \(error)")
                completion(false, nil, nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(false, nil, nil)
                return
            }
            
            print("Received data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let latestVersion = json["version"] as? String,
                  let downloadURL = json["download_url"] as? String,
                  let releaseNotes = json["release_notes"] as? String else {
                print("Failed to parse version.json")
                completion(false, nil, nil)
                return
            }
            
            print("Latest version: \(latestVersion)")
            let needsUpdate = self.compareVersions(current: self.currentVersion, latest: latestVersion)
            print("Update needed: \(needsUpdate)")
            
            completion(needsUpdate, downloadURL, releaseNotes)
        }
        task.resume()
    }
    
    private func compareVersions(current: String, latest: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        
        print("Comparing versions:")
        print("Current components: \(currentComponents)")
        print("Latest components: \(latestComponents)")
        
        for (current, latest) in zip(currentComponents, latestComponents) {
            if latest > current {
                return true
            } else if latest < current {
                return false
            }
        }
        
        return latestComponents.count > currentComponents.count
    }
} 