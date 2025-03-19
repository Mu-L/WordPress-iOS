// FIXME: Having issues with CocoaLumberjack as a transitive dependency when added to Objective-C files
//@import CocoaLumberjack;

// Without this explicitly step, the framework fails to compile with ddLogLevel symbol not found.
DDLogLevel ddLogLevel = DDLogLevelInfo;

#define DDLogInfo(frmt, ...) NSLog((@"[INFO] " frmt), ##__VA_ARGS__)
#define DDLogError(frmt, ...) NSLog((@"[ERROR] " frmt), ##__VA_ARGS__)
