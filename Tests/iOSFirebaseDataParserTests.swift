import XCTest
@testable import iOSFirebaseDataParser
import CSV

final class iOSFirebaseDataParserTests: XCTestCase {
    
    var main: Main!
    
    override func setUp() {
        super.setUp()
        main = Main()
    }
    
    override func tearDown() {
        main = nil
        super.tearDown()
    }

    func testValidateHeaderValid() {
        let validHeader1 = ["Device model", "OS with version", "Active users", "New users"]
        let validHeader2 = ["OS with version", "Device model", "Active users", "New users"]
        
        do {
            try main.validateHeader(row: validHeader1)
            try main.validateHeader(row: validHeader2)
        } catch {
            XCTFail("Header validation failed with error: \(error)")
        }
    }
    
    func testValidateHeaderInvalid() {
        let invalidHeader = ["Invalid header", "Data"]
        
        XCTAssertThrowsError(try main.validateHeader(row: invalidHeader)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "Error")
            XCTAssertEqual(nsError.code, 1)
            XCTAssertEqual(nsError.userInfo[NSLocalizedDescriptionKey] as? String, "Invalid header row. Expected 'Device model' or 'OS with version'.")
        }
    }
    
    func testLoadCSV() {
        let testCSV = """
        # Comment line
        # Another comment line
        Device model,OS with version,Active users,New users
        iPhone,iOS 15,100,50
        iPad,iOS 14,200,100
        """
        
        let tempFile = createTempCSV(content: testCSV)
        do {
            let csvReader = try main.loadCSV(from: tempFile)
            let rows = collectRows(from: csvReader)
            XCTAssertGreaterThan(rows.count, 0, "CSV rows should be loaded")
        } catch {
            XCTFail("Error loading CSV: \(error)")
        }
    }
    
    func testExtractRelevantData() {
        let testCSV = """
        # Comment line
        Device model,OS with version,Active users,New users
        iPhone,iOS 15,100,50
        iPad,iOS 14,200,100
        """
        
        let tempFile = createTempCSV(content: testCSV)
        do {
            let csvReader = try main.loadCSV(from: tempFile)
            let extractedData = main.extractRelevantData(from: csvReader)
            XCTAssertTrue(extractedData.contains("iPhone,iOS 15,100,50"))
            XCTAssertTrue(extractedData.contains("iPad,iOS 14,200,100"))
        } catch {
            XCTFail("Error extracting data: \(error)")
        }
    }
    
    func testParseDataByiOSVersion() {
        let testData = """
        iPhone,iOS 15,100
        iPad,iOS 14,200
        iPhone,iOS 15,150
        """
        
        let parsedData = main.parseData(testData, by: .iOSVersion)
        XCTAssertEqual(parsedData["iOS 15"], 250)
        XCTAssertEqual(parsedData["iOS 14"], 200)
    }
    
    func testParseDataByDeviceModel() {
        let testData = """
        iPhone,iOS 15,100
        iPad,iOS 14,200
        iPhone,iOS 15,150
        """
        
        let parsedData = main.parseData(testData, by: .deviceModel)
        XCTAssertEqual(parsedData["iPhone"], 250)
        XCTAssertEqual(parsedData["iPad"], 200)
    }
    
    // Helpers
    private func createTempCSV(content: String) -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
        try? content.write(to: tempFile, atomically: true, encoding: .utf8)
        return tempFile.path
    }
    
   private func collectRows(from reader: CSVReader) -> [[String]] {
        var rows: [[String]] = []
        
        while let row = reader.next() {
            rows.append(row)
        }
        
        return rows
    }
}
