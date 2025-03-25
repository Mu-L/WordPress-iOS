#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "Keystone-Swift.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)configureSections
{
    self.sections = @[
        @(PostSettingsSectionMeta),
        @(PostSettingsSectionFeaturedImage),
        @(PostSettingsSectionMoreOptions),
        @(PostSettingsSectionPageAttributes)
    ];
}

- (Page *)page
{
    if ([self.apost isKindOfClass:[Page class]]) {
        return (Page *)self.apost;
    }
    
    return nil;
}

@end
