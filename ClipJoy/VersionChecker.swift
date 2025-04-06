import Foundation

class VersionChecker {
    static let shared = VersionChecker()
    
    private let versionURL = URL(string: "https://raw.githubusercontent.com/sourceprojects/Clipboard/master/ClipJoy/version.json")!
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
            
            print("Latest version from JSON: \(latestVersion)")
            let needsUpdate = self.compareVersions(current: self.currentVersion, latest: latestVersion)
            print("Update check result: \(needsUpdate)")
            
            completion(needsUpdate, downloadURL, releaseNotes)
        }
        task.resume()
    }
    
    private func compareVersions(current: String, latest: String) -> Bool {
        print("\nDetailed version comparison:")
        print("Comparing current version: \(current) with latest version: \(latest)")
        
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        
        print("Current version components: \(currentComponents)")
        print("Latest version components: \(latestComponents)")
        
        for (index, (current, latest)) in zip(currentComponents, latestComponents).enumerated() {
            print("Comparing component \(index): current=\(current) vs latest=\(latest)")
            if latest > current {
                print("Latest version component is greater -> update needed")
                return true
            } else if latest < current {
                print("Current version component is greater -> no update needed")
                return false
            }
            print("Components are equal, continuing to next component")
        }
        
        let result = latestComponents.count > currentComponents.count
        print("All compared components are equal. Checking length: latest=\(latestComponents.count) vs current=\(currentComponents.count)")
        print("Final result: \(result ? "update needed" : "no update needed")")
        return result
    }
} 