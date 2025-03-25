#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif

@import UIKit;

extern NSString * const SettingsTableViewCellReuseIdentifier;

@interface SettingTableViewCell : UITableViewCell

- (instancetype)initWithLabel:(NSString *)label editable:(BOOL)editable reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, copy) NSString *textValue;
@property (nonatomic, assign) BOOL editable;

@end
