//
//  AGAppDelegate.m
//  DropCloud
//
//  Created by Arvid Gerstmann on 17/05/14.
//  Copyright (c) 2014 Arvid Gerstmann. All rights reserved.
//

#import "AGAppDelegate.h"
#import "AGStatusItemView.h"
#import "AGCloudCommunication.h"
#import "AGCredentials.h"
#import "NSAttributedString+Hyperlink.h"
#import "AGLoadingStatusItemView.h"
#import "AGPreferences.h"

@interface AGAppDelegate ()

#pragma mark General Properties
@property (nonatomic, strong) AGCloudCommunication *cloud;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) AGLoadingStatusItemView *statusItemView;


#pragma mark Main Window
@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *settingsMenuItem;
@property (weak) IBOutlet NSMenuItem *aboutMenuItem;
@property (weak) IBOutlet NSMenuItem *quitMenuItem;

@property (weak) IBOutlet NSTextField *serverSettingsLabel;
@property (weak) IBOutlet NSTextField *serverUrlTextfield;
@property (weak) IBOutlet NSTextField *serverPathTextfield;
@property (weak) IBOutlet NSButton *selfSignedCertsCheckbox;

@property (weak) IBOutlet NSTextField *userSettingsLabel;
@property (weak) IBOutlet NSTextField *usernameTextfield;
@property (weak) IBOutlet NSSecureTextField *passwordTextfield;

@property (weak) IBOutlet NSButton *saveButton;


#pragma mark About Window
@property (unsafe_unretained) IBOutlet NSWindow *aboutWindow;
@property (weak) IBOutlet NSTextField *developedByLabel;
@property (weak) IBOutlet NSTextField *aboutTextfield;
@property (weak) IBOutlet NSButton *updatesButton;


#pragma mark Actions
- (IBAction)settingsAction:(id)sender;
- (IBAction)aboutAction:(id)sender;
- (IBAction)quitAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end

@implementation AGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Init.
}

- (void)awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
    self.statusItemView = [[AGLoadingStatusItemView alloc] initWithStatusItem:self.statusItem];
    self.statusItemView.menu = self.statusMenu;
    self.statusItemView.image = [NSImage imageNamed:@"menubar_icon"];
    self.statusItemView.highlightImage = [NSImage imageNamed:@"menubar_icon_inverse"];
    [self.statusItemView addObserver:@selector(fileDropped:) withTarget:self forEvent:AGStatusItemEventFileDropped];
    self.statusItem.view = self.statusItemView;

    self.cloud = [AGCloudCommunication sharedManager];
    self.cloud.baseUrl = [AGPreferences sharedInstance].baseURL;
    self.cloud.remoteDirectoryPath = [AGPreferences sharedInstance].remoteDirectoryPath;

    self.serverUrlTextfield.stringValue = self.cloud.baseUrl;
    self.serverPathTextfield.stringValue = self.cloud.remoteDirectoryPath;

    [self.aboutTextfield setAllowsEditingTextAttributes:YES];
    [self.aboutTextfield setSelectable:YES];

    NSURL *url = [NSURL URLWithString:@"https://github.com/leandros/owndrop"];
    NSFont *font = [NSFont fontWithName:@"HelveticaNeue-Light" size:13];
    NSDictionary *attr = @{
            NSFontAttributeName : font
    };
    NSMutableAttributedString *aboutString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"abouttext", nil) attributes:attr];
    [aboutString appendAttributedString:[NSAttributedString hyperlinkFromString:@"https://GitHub.com/Leandros/ownDrop" withURL:url attributes:attr]];
    [aboutString appendAttributedString:[[NSAttributedString alloc] initWithString:@")" attributes:attr]];
    self.aboutTextfield.attributedStringValue = aboutString;

    NSFont *boldFont = [NSFont fontWithName:@"HelveticaNeue-Bold" size:13];
    NSDictionary *boldAttr = @{
            NSFontAttributeName : boldFont
    };
    self.developedByLabel.attributedStringValue = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"developedby", nil) attributes:boldAttr];
    [self.updatesButton setTitle:NSLocalizedString(@"checkforupdates", nil)];

    self.settingsMenuItem.title = NSLocalizedString(@"settings", nil);
    self.aboutMenuItem.title = NSLocalizedString(@"about", nil);
    self.quitMenuItem.title = NSLocalizedString(@"quit", nil);

    self.serverSettingsLabel.stringValue = NSLocalizedString(@"serversettings", nil);
    [self.serverUrlTextfield.cell setPlaceholderString:NSLocalizedString(@"serverurl", nil)];
    [self.serverPathTextfield.cell setPlaceholderString:NSLocalizedString(@"serverpath", nil)];

    self.userSettingsLabel.stringValue = NSLocalizedString(@"usersettings", nil);
    [self.usernameTextfield.cell setPlaceholderString:NSLocalizedString(@"username", nil)];
    if ([[AGCredentials credentials].userName length] > 0) {
        [self.usernameTextfield setStringValue:[AGCredentials credentials].userName];
    }
    [self.passwordTextfield.cell setPlaceholderString:NSLocalizedString(@"password", nil)];
    // Shows the Keychain unlock dialog.
    if ([[AGCredentials credentials].password length] > 0) {
        [self.passwordTextfield setStringValue:[AGCredentials credentials].password];
    } else {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"enterpassword", nil);

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }

    self.selfSignedCertsCheckbox.state = [AGPreferences sharedInstance].allowSelfSignedSSLCerts ? NSOnState : NSOffState;
}


#pragma mark -
#pragma mark Menu Actions -

- (IBAction)settingsAction:(id)sender {
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)aboutAction:(id)sender {
    [self.aboutWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quitAction:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)saveAction:(id)sender {
    [AGPreferences sharedInstance].baseURL = self.serverUrlTextfield.stringValue;
    [AGPreferences sharedInstance].remoteDirectoryPath = self.serverPathTextfield.stringValue;
    if (self.usernameTextfield.stringValue.length > 0 && self.passwordTextfield.stringValue.length > 0) {
        [[AGCredentials credentials] setName:self.usernameTextfield.stringValue password:self.passwordTextfield.stringValue];
    }

    if (self.selfSignedCertsCheckbox.state == NSOnState) {
        [AGPreferences sharedInstance].allowSelfSignedSSLCerts = YES;
    } else if (self.selfSignedCertsCheckbox.state == NSOffState) {
        [AGPreferences sharedInstance].allowSelfSignedSSLCerts = NO;
    }

    // Update cloud.
    self.cloud.baseUrl = [AGPreferences sharedInstance].baseURL;
    self.cloud.remoteDirectoryPath = [AGPreferences sharedInstance].remoteDirectoryPath;
    self.cloud.allowSelfSignedCerts = [AGPreferences sharedInstance].allowSelfSignedSSLCerts;

    [self.window close];
}


#pragma mark -
#pragma mark File Upload -

- (void)fileDropped:(id <NSDraggingInfo>)sender {
    NSArray *fileNames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSString *fileName = fileNames[0];

    [self.cloud uploadFile:fileName progress:^(float percentCompleted) {
        [self.statusItemView setLoading:YES];
        [self.statusItemView setProgress:percentCompleted];
    }           completion:^(NSString *remoteFilePath, NSError *uploadError) {
        [self.statusItemView setLoading:NO];
        if (!uploadError) {
            [self.cloud shareFile:remoteFilePath completion:^(NSString *url, NSError *shareError) {
                if (!shareError) {
                    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                    [pasteboard clearContents];
                    [pasteboard setString:url forType:NSStringPboardType];

                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.title = [NSString stringWithFormat:NSLocalizedString(@"uploadcomplete", nil), fileName.lastPathComponent];
                    notification.informativeText = NSLocalizedString(@"urlcopied", nil);

                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
                } else {
                    NSLog(@"Share Error: %@", shareError);

                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.title = NSLocalizedString(@"errorsharing", nil);
                    notification.informativeText = shareError.localizedDescription;

                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
                }
            }];
        } else {
            NSLog(@"Upload Error: %@", uploadError);

            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = NSLocalizedString(@"erroruploading", nil);
            notification.informativeText = uploadError.localizedDescription;

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
    }];
}
@end
