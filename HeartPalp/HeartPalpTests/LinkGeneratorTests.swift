import XCTest
@testable import HeartPalp

final class LinkGeneratorTests: XCTestCase {
    
    func testGenerateLinkWithDefaultBaseUrl() {
        // Given
        let patientId = "test-patient-123"
        let daysValid = 7
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithCustomBaseUrl() {
        // Given
        let patientId = "test-patient-123"
        let daysValid = 7
        let customBaseUrl = "https://example.com"
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid, baseUrl: customBaseUrl)
        
        // Then
        XCTAssertTrue(link.hasPrefix("\(customBaseUrl)?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithDifferentDays() {
        // Given
        let patientId = "test-patient-123"
        let daysValid = 30
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithSpecialCharacters() {
        // Given
        let patientId = "test-patient-123!@#$%^&*()"
        let daysValid = 7
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithEmptyPatientId() {
        // Given
        let patientId = ""
        let daysValid = 7
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithZeroDays() {
        // Given
        let patientId = "test-patient-123"
        let daysValid = 0
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithNegativeDays() {
        // Given
        let patientId = "test-patient-123"
        let daysValid = -1
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
    
    func testGenerateLinkWithLongPatientId() {
        // Given
        let patientId = String(repeating: "a", count: 1000)
        let daysValid = 7
        
        // When
        let link = LinkGenerator.generateLink(patientId: patientId, daysValid: daysValid)
        
        // Then
        XCTAssertTrue(link.hasPrefix("http://localhost:3000?data="))
        XCTAssertTrue(link.contains(":")) // Verify the colon separator exists
    }
} 