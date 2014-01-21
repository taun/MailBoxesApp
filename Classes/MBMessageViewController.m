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
#import "MBMimeImage+IMAP.h"
#import "MBMimeData+IMAP.h"
#import "MBMultiAlternative.h"
#import "MBAddress+IMAP.h"
#import "MBMessageView.h"
#import "MBMessageHeaderView.h"
#import "MBox+IMAP.h"
#import "MBAccount+IMAP.h"

#import "MailBoxesAppDelegate.h"
#import "MBAccountsCoordinator.h"

#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface MBMessageViewController ()

@property (strong, nonatomic) NSArray* cachedOrderedMessageParts;

-(NSAttributedString*) attributedStringFromMessage: (MBMessage*) message;

@end

@implementation MBMessageViewController

-(void) setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    if ([representedObject isKindOfClass: [MBMessage class]]) {
        MBMessage* myMessage = (MBMessage*)representedObject;
        if ([myMessage.isFullyCached boolValue] == NO ) {
            // need to load the body
            // ask accountsCoordinator to load body for selectedMessage
            // request will be processed in background and should show up in view when done.
            NSManagedObjectID* accountID = [[[myMessage mbox] accountReference] objectID];
            NSManagedObjectID* messageID = [myMessage objectID];
            MailBoxesAppDelegate *app = (MailBoxesAppDelegate *)[[NSApplication sharedApplication] delegate];
            [app.accountsCoordinator loadFullMessageID: messageID forAccountID: accountID];
        }

    }
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // init code
//        [[self view] setWantsLayer: YES];
//        [self.view.window visualizeConstraints: self.view.constraints];
////        [NSAnimationContext beginGrouping];
////        [[NSAnimationContext currentContext] setDuration: 1.0];
////        
////        CABasicAnimation* alphaAnim = [CABasicAnimation animationWithKeyPath: @"alphaValue"];
////        [alphaAnim setFromValue: [NSNumber numberWithFloat: 0.0]];
////        [alphaAnim setToValue: [NSNumber numberWithFloat: 1.0]];
////        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: alphaAnim, @"alphaValue", nil];
////        [[self view] setAnimations: dict];
//    }
//    return self;
//}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString: @"defaultContent"]) {
        [self refreshMessageDisplay: nil];
    } else if ([keyPath isEqualToString: @"data"]) {
//        [self displayNode: object];
    }

}

-(void) setMessage:(MBMessage *)message {
    if (message != _message) {
        _message = message;
//        [_message addObserver: self forKeyPath: @"defaultContent" options: NSKeyValueObservingOptionNew context: NULL];
//        self.messageHeader.message = _message;
    }
    [self refreshMessageDisplay: nil];
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
    MBMessageView* messageView = (MBMessageView*)self.view;
    [messageView setTitle: self.message.subject];

    NSSize messageSize = self.view.frame.size;
    CGFloat headerHeight = self.messageHeader.frame.size.height;
    CGPoint headerOrigin = self.messageHeader.frame.origin;

    CGFloat dataViewHeight = messageSize.height-headerHeight-40;
    CGFloat dataViewWidth = messageSize.width - 40;
    
    NSTextView* dataView;
    NSRect dataViewFrame = NSMakeRect(headerOrigin.x, 0, dataViewWidth, FLT_MAX);
    dataView = [[NSTextView alloc] initWithFrame: dataViewFrame];
    [dataView setEditable: NO];
    [dataView setMinSize: NSMakeSize(0, dataViewHeight)];
    [dataView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [dataView setHorizontallyResizable: NO];
    [dataView setVerticallyResizable: YES];
//    [dataView setAutoresizingMask: NSViewWidthSizable]; //??
    [dataView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    [[dataView textContainer] setContainerSize: NSMakeSize(dataViewWidth, FLT_MAX)]; // -40 based on default margin. Need way to not hard code this.
                                                                                           // message frame size is correct but header is not yet laidout so incorrect width.
    [[dataView textContainer] setWidthTracksTextView:YES];
    
    [dataView setString: @"Loading....."];
    if (self.message) {
        [[dataView textStorage] setAttributedString: [self attributedStringFromMessage: self.message]];
    }
//    [[self.messageBodyViewContainer superview] replaceSubview: self.messageBodyViewContainer with: dataView];
    NSTextContainer* tc = [dataView textContainer];
    NSLayoutManager* lm = [tc layoutManager];
    [lm glyphRangeForTextContainer: tc];
    
    CGFloat textHeight = [lm usedRectForTextContainer: tc].size.height;
//    NSSize tcSize = [tc containerSize];
    
//    [tc setContainerSize: NSMakeSize(tcSize.width, textHeight+30)];
    
    if (self.messageBodyView) {
        [self.messageBodyViewContainer replaceSubview: self.messageBodyView with: dataView];
    } else {
        [self.messageBodyViewContainer addSubview: dataView];
    }
    self.messageBodyView = dataView; // save for future use in replaceSubview:

    NSLayoutPriority hcompRes = [dataView contentCompressionResistancePriorityForOrientation: NSLayoutConstraintOrientationVertical];
    NSLayoutPriority vcompRes = [dataView contentCompressionResistancePriorityForOrientation: NSLayoutConstraintOrientationHorizontal];

    NSDictionary *views = NSDictionaryOfVariableBindings(dataView, _messageBodyViewContainer);

    [self.messageBodyViewContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[dataView]-0-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];

    [self.messageBodyViewContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[dataView]-0-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views]];
    
    [dataView setContentCompressionResistancePriority: NSLayoutPriorityRequired forOrientation: NSLayoutConstraintOrientationVertical];
    [self.messageBodyViewContainer setContentCompressionResistancePriority: NSLayoutPriorityRequired forOrientation: NSLayoutConstraintOrientationVertical];
    
//    [self.messageBodyViewContainer addSubview: dataView];
//    [self.messageBodyViewContainer setFrame: [dataView frame]];
    CGFloat finalMessageHeight = textHeight+headerHeight+40;
    CGFloat originX = 0.0;
    CGFloat originY = 0.0;
    
    NSRect vf = self.view.frame;
    [self.view setFrame: NSMakeRect(originX, originY, vf.size.width, finalMessageHeight)];
//    NSSize isize = [self.view fittingSize];
//    [dataView setFrame: [(NSView*)self.messageBodyViewContainer frame]];
    
    [self.messageBodyViewContainer setNeedsDisplay: YES];
}

-(NSAttributedString*) attributedStringFromMessage:(MBMessage *)message {
    NSDictionary* options = @{MBRichMessageViewAttributeName:@YES};
    NSDictionary* attributes = nil;

    NSMutableAttributedString* composition = [[NSMutableAttributedString alloc] initWithString: @"" attributes: attributes];
    for (MBMime* node in message.childNodes) {
        NSAttributedString* subComposition = [node asAttributedStringWithOptions: options attributes: attributes];
        if (subComposition) {
            [composition appendAttributedString: subComposition];
        }
    }
    return [composition copy];
}

@end
