// This conformance was added during the Xcode 16 migration to silence the
// dozens of false-positive warnings (any @unchecked conformance is tech debt).
extension AnyHashable: @retroactive @unchecked Sendable {}
