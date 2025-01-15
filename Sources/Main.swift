import Figlet
import ArgumentParser
import CSV
import Foundation
import SwiftyTextTable

@main
struct Main: ParsableCommand {
    
    @Option(help: "Specify the input CSV file path")
    var source = ""
    
    @Option(help: "Choose between 'os' for iOS versions or 'devices' for devices models")
    var mode: String = ""
    
    public func run() throws {
        try validateOptions()
        
        Figlet.say("STATS")
        do {
            let csvReader = try loadCSV(from: source)
            
            let content = extractRelevantData(from: csvReader)
            
            if mode.lowercased() == "os" {
                let iOSUsageData = parseData(content, by: .iOSVersion)
                displayTable(for: iOSUsageData, label: "iOS Version")
            } else if mode.lowercased() == "devices" {
                let deviceUsageData = parseData(content, by: .deviceModel)
                displayTable(for: deviceUsageData, label: "Device Model")
            } else {
                print("Invalid mode. Use 'ios' or 'device'.")
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func validateOptions() throws {
          if source.isEmpty {
              throw ValidationError("The CSV file path must be provided.")
          }

          let validModes = ["os", "devices"]
          if !validModes.contains(mode.lowercased()) {
              throw ValidationError("Invalid mode. Use 'ios' or 'device'.")
          }
      }
    
    func loadCSV(from path: String) throws -> CSVReader {
        guard let inputStream = InputStream(fileAtPath: path) else {
            throw NSError(domain: "Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open file at path: \(path)"])
        }
        
        let reader = try CSVReader(stream: inputStream, hasHeaderRow: true)
        
        while let row = reader.next() {
            if let firstCell = row.first, !firstCell.hasPrefix("#") {
                try validateHeader(row: row)
                break
            }
        }
        
        return reader
    }
    
    func validateHeader(row: [String]) throws {
        // Ensure the row contains "Device model" or "OS with version"
        if !(row.contains("Device model") || row.contains("OS with version")) {
            throw NSError(domain: "Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid header row. Expected 'Device model' or 'OS with version'."])
        }
    }
    
    func extractRelevantData(from reader: CSVReader) -> String {
        var data = ""
        while reader.next() != nil {
            guard let row = reader.currentRow, row.contains(where: { !$0.isEmpty }) else {
                continue
            }
            
            if shouldIgnoreRow(row) {
                continue
            }
            
            data.append(row.joined(separator: ","))
            data.append("\n")
        }
        return data
    }
    
    func shouldIgnoreRow(_ row: [String]) -> Bool {
        guard let firstCell = row.first else { return true }
        return firstCell.starts(with: "#") || firstCell.starts(with: "OS with")
    }
    
    func parseData(_ data: String, by grouping: Grouping) -> [String: Int] {
        let lines = data.split { $0.isNewline }
        var usageData: [String: Int] = [:]
        
        for line in lines {
            let components = line.split(separator: ",")
            guard components.count > 2,
                  let key = grouping == .iOSVersion
                    ? components[safe: 1]?.split(separator: ".").first.map(String.init)
                    : components[safe: 0].map(String.init),
                  let numberOfUsers = Int(components[safe: 2] ?? "") else {
                continue
            }
            
            usageData[key, default: 0] += numberOfUsers
        }
        
        return usageData
    }
    
    private func displayTable(for usageData: [String: Int], label: String) {
        let totalUsers = usageData.values.reduce(0, +)
        guard totalUsers > 0 else {
            print("No user data available.")
            return
        }
        
        let labelColumn = TextTableColumn(header: label)
        let usageColumn = TextTableColumn(header: "Usage (%)")
        let userCountColumn = TextTableColumn(header: "User count")
        var table = TextTable(columns: [labelColumn, usageColumn, userCountColumn])
        var totalPercentage: Double = 0.0
        
        for (key, numberOfUsers) in usageData.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(numberOfUsers) / Double(totalUsers) * 100
            guard percentage > 0 else { continue }
            
            let formattedPercentage = String(format: "%.2f", percentage)
            totalPercentage += percentage
            table.addRow(values: ["\(key)", "\(formattedPercentage)%", "\(numberOfUsers)"])
        }
        
        print(table.render())
    }
}

enum Grouping {
    case iOSVersion
    case deviceModel
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
