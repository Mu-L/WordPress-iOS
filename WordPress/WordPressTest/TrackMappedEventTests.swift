import Testing
import WordPressShared
import AutomatticTracks
import AutomatticTracksEvents

@testable import WordPress

struct TrackMappedEventTests {
    @Test func verifyTrackEventNameMapping() throws {
        for index in 0..<WPAnalyticsStat.maxValue.rawValue {
            let stat = try #require(WPAnalyticsStat(rawValue: index))
            let map = try #require(TracksMappedEvent.make(for: stat))

            let event = AutomatticTracksEvents.TracksEvent()
            event.uuid = UUID()
            event.eventName = "wpios_\(map.name)"

            try event.validateObject()
        }
    }
}
