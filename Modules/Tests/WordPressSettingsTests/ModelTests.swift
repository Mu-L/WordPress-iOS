import Foundation
import Testing

@Test("Validate JSON")
func performTest1() {
    let data = Bundle.module.url(forResource: "test1", withExtension: "json")
    #expect(data != nil)
}
