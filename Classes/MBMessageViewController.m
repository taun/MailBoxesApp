//
//  MBMessageViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessageViewController.h"
#import "MBMessage+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMimeData+IMAP.h"

#import <QuartzCore/QuartzCore.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation MBMessageViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // init code
        [[self view] setWantsLayer: YES];
//        [NSAnimationContext beginGrouping];
//        [[NSAnimationContext currentContext] setDuration: 1.0];
//        
//        CABasicAnimation* alphaAnim = [CABasicAnimation animationWithKeyPath: @"alphaValue"];
//        [alphaAnim setFromValue: [NSNumber numberWithFloat: 0.0]];
//        [alphaAnim setToValue: [NSNumber numberWithFloat: 1.0]];
//        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: alphaAnim, @"alphaValue", nil];
//        [[self view] setAnimations: dict];
    }
    return self;
}


- (IBAction)showMessageDebug:(id)sender {
    DDLogCVerbose(@"[%@ %@] Message: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.message);
}

- (IBAction)showPartsInLog:(id)sender {
    NSSet* parts = self.message.allParts;
    for (id part in parts) {
        DDLogCVerbose(@"Part: %@", part);
        if ([part isKindOfClass:[MBMime class]]) {
            MBMimeData*  data = [(MBMime*)part data];
            if (data) {
                DDLogCVerbose(@"Data: %@", data);
            }
        }
    }
}

- (IBAction)refreshMessageDisplay:(id)sender {
    [self.message.managedObjectContext save: nil];
}
@end
