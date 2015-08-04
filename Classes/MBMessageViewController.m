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
#import "MBBodyStructureInlineView.h"

#import "MailBoxesAppDelegate.h"
#import "MBAccountsCoordinator.h"

#import <MoedaeMailPlugins/MoedaeMailPlugins.h>

#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>


static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface MBMessageViewController ()

@property (strong, nonatomic) NSArray* cachedOrderedMessageParts;

-(NSAttributedString*) attributedStringFromMessage: (MBMessage*) message;

@end

@implementation MBMessageViewController

-(NSArray*) emailSortDescriptors {
    NSSortDescriptor* emailSorting = [NSSortDescriptor sortDescriptorWithKey: @"email" ascending: YES];
    NSSortDescriptor* nameSorting = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
    return @[nameSorting,emailSorting];
}

#pragma message "ToDo: need intermediate class which serves as store interface. Converts from persistent object to local object avoiding manual conversions like below."
-(SimpleRFC822Address*) cachedAddressesTo {
    if (_cachedAddressesTo == nil) {
        MBMessage* message = (MBMessage*) self.representedObject;
//        NSSortDescriptor* sorting = [NSSortDescriptor sortDescriptorWithKey: @"email" ascending: YES];
//        _cachedAddressesBcc = [message.addressesTo sortedArrayUsingDescriptors: @[sorting]];
        _cachedAddressesTo = [message.addressesTo newSimpleAddress];
        [self setSelectionForController: self.addressesToArrayController];
    }
    return _cachedAddressesTo;
}
-(SimpleRFC822Address*) cachedAddressesBcc {
    if (_cachedAddressesBcc == nil) {
        MBMessage* message = (MBMessage*) self.representedObject;
        _cachedAddressesBcc = [message.addressesBcc newSimpleAddress];
        [self setSelectionForController: self.addressesBccArrayController];
    }
    return _cachedAddressesBcc;
}
-(SimpleRFC822Address*) cachedAddressesCc {
    if (_cachedAddressesCc == nil) {
        MBMessage* message = (MBMessage*) self.representedObject;
        _cachedAddressesCc = [message.addressesCc newSimpleAddress];
        [self setSelectionForController: self.addressesCcArrayController];
    }
    return _cachedAddressesCc;
}
-(void) setSelectionForController: (NSTreeController*) controller {
    
}

-(void) awakeFromNib {
    if ([self.representedObject isKindOfClass: [MBMessage class]]) {
        
//        [self.view setTranslatesAutoresizingMaskIntoConstraints: NO];
        [self.view setContentCompressionResistancePriority: NSLayoutPriorityFittingSizeCompression-41 forOrientation: NSLayoutConstraintOrientationVertical];
        
        MBMessage* myMessage = (MBMessage*)self.representedObject;
        if ([myMessage.isFullyCached boolValue] == NO ) {
            // need to load the body
            // ask accountsCoordinator to load body for selectedMessage
            // request will be processed in background and should show up in view when done.
//            NSManagedObjectID* accountID = [[[myMessage mbox] accountReference] objectID];
//            NSManagedObjectID* messageID = [myMessage objectID];
            [[MBAccountsCoordinator sharedInstanceForUser: myMessage.mbox.accountReference.user] loadFullMessage: myMessage forAccount: [[myMessage mbox] accountReference]];
        }
        
        //Get this from user preferences or toggle by a control
        _options = [MMPMessageViewOptions new];
        _options.asPlainText = NO;

        [self.messageBodyViewContainer setMessage: myMessage options: self.options];
    }
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // init code
//        [[self view] setWantsLayer: YES];
//        [self.view.window visualizeConstraints: self.view.constraints];
// //        [NSAnimationContext beginGrouping];
// //        [[NSAnimationContext currentContext] setDuration: 1.0];
// //
// //        CABasicAnimation* alphaAnim = [CABasicAnimation animationWithKeyPath: @"alphaValue"];
// //        [alphaAnim setFromValue: [NSNumber numberWithFloat: 0.0]];
// //        [alphaAnim setToValue: [NSNumber numberWithFloat: 1.0]];
// //        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: alphaAnim, @"alphaValue", nil];
// //        [[self view] setAnimations: dict];
//    }
//    return self;
//}

//-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//
//    if ([keyPath isEqualToString: @"defaultContent"]) {
//        [self refreshMessageDisplay: nil];
//    } else if ([keyPath isEqualToString: @"data"]) {
////        [self displayNode: object];
//    }
//
//}
-(void) reloadMessage {
    self.messageBodyViewContainer.options = self.options;
    [self.messageBodyViewContainer reloadViews];
}

#pragma mark - Actions
- (IBAction)showMessageAsPlainText:(id)sender {
    self.options.asPlainText = YES;
    [self reloadMessage];
}

- (IBAction)showMessageAsRichText:(id)sender {
    self.options.asPlainText = NO;
    [self reloadMessage];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (IBAction)showConstraints:(id)sender {
    NSString* viewsDesc = [self.view performSelector: NSSelectorFromString(@"_subtreeDescription")];
    DDLogCVerbose(@"[%@ %@] Subviews Desc: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), viewsDesc);
    NSMutableArray* constraints = [NSMutableArray new];
    for (NSView* subview in [[[[[self.view subviews] objectAtIndex:0]subviews]objectAtIndex:0]subviews]) {
        [constraints addObjectsFromArray: [subview constraintsAffectingLayoutForOrientation: NSLayoutConstraintOrientationHorizontal]];
        for (NSView* subsubView in subview.subviews) {
            [constraints addObjectsFromArray: [subview constraintsAffectingLayoutForOrientation: NSLayoutConstraintOrientationHorizontal]];
        }
    }
    [constraints addObjectsFromArray: [self.view constraintsAffectingLayoutForOrientation: NSLayoutConstraintOrientationHorizontal]];
    [self.view.window visualizeConstraints: constraints];
}
#pragma clang diagnostic pop

- (IBAction)toggleViewOutlines:(id)sender {
    self.options.showViewOutlines = !self.options.showViewOutlines;
    [self reloadMessage];
}

- (IBAction)changeVerticalHugging:(id)sender {
    if (self.options.verticalHuggingPriority == 750) {
        self.options.verticalHuggingPriority = 1000.0;
    } else {
        self.options.verticalHuggingPriority = 750.0;
    }
    [self reloadMessage];
}

- (IBAction)debugLayoutSubtree:(id)sender {
    [self.messageBodyViewContainer layoutSubtreeIfNeeded];
}

-(void) dealloc {
    [self.view.window visualizeConstraints: [NSArray new]];
}

- (IBAction)showPartsPopover:(NSButton *)sender {
    if (self.partsPopover.isShown) {
        [self.partsPopover close];
    } else {
        NSRectEdge* edge;
        self.partsPopover.contentViewController.representedObject = self.representedObject;
//        [self.partsPopover.contentViewController.view setTranslatesAutoresizingMaskIntoConstraints: NO];
        [self.partsPopover showRelativeToRect: sender.bounds ofView: sender preferredEdge: NSMaxXEdge];
    }
}

- (IBAction)showRecipientAddressPopover:(id)sender {
    SimpleRFC822Address* renamed = [self.cachedAddressesTo copy];
    renamed.name = @"To:";
    [self.popoverAddressesArrayController setContent: renamed] ;
    [self.addressPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMaxXEdge];
}

- (IBAction)showBccAddressPopover:(id)sender {
    [self.popoverAddressesArrayController setContent: self.cachedAddressesBcc] ;
    [self.addressPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMaxXEdge];
}

- (IBAction)showCcAddressPopover:(id)sender {
    [self.popoverAddressesArrayController setContent: self.cachedAddressesCc] ;
    [self.addressPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMaxXEdge];
}

- (IBAction)showMessageDebug:(id)sender {
    MBMessage* message = (MBMessage*) self.representedObject;
    MBox* box = message.mbox;
    DDLogCVerbose(@"[%@ %@] Box: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), box);
    DDLogCVerbose(@"[%@ %@] Message: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), message);
    DDLogCVerbose(@"[%@ %@] AddressFrom: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), message.addressFrom);
    DDLogCVerbose(@"[%@ %@] AddressTo: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), message.addressesTo);
}

- (IBAction)showPartsInLog:(id)sender {
    NSSet* parts = [(MBMessage*)(self.representedObject) allMimeParts];
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

#pragma mark - Popover Delegate
- (void)popoverWillShow:(NSNotification *)notification {
    
}



//- (IBAction)refreshMessageDisplay:(id)sender {
//    MBMessageView* messageView = (MBMessageView*)self.view;
//    [messageView setTitle: [self.representedObject subject]];
//
//    NSSize messageSize = self.view.frame.size;
//    CGFloat headerHeight = self.messageHeader.frame.size.height;
//    CGPoint headerOrigin = self.messageHeader.frame.origin;
//
//    CGFloat dataViewHeight = messageSize.height-headerHeight-40;
//    CGFloat dataViewWidth = messageSize.width - 40;
//    
//    NSTextView* dataView;
//    NSRect dataViewFrame = NSMakeRect(headerOrigin.x, 0, dataViewWidth, FLT_MAX);
//    dataView = [[NSTextView alloc] initWithFrame: dataViewFrame];
//    [dataView setEditable: NO];
//    [dataView setMinSize: NSMakeSize(0, dataViewHeight)];
//    [dataView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
//    [dataView setHorizontallyResizable: NO];
//    [dataView setVerticallyResizable: YES];
// //    [dataView setAutoresizingMask: NSViewWidthSizable]; //??
//    [dataView setTranslatesAutoresizingMaskIntoConstraints: NO];
//    
//    [[dataView textContainer] setContainerSize: NSMakeSize(dataViewWidth, FLT_MAX)]; // -40 based on default margin. Need way to not hard code this.
//                                                                                           // message frame size is correct but header is not yet laidout so incorrect width.
//    [[dataView textContainer] setWidthTracksTextView:YES];
//    
//    [dataView setString: @"Loading....."];
//    if (self.representedObject) {
//        [[dataView textStorage] setAttributedString: [self attributedStringFromMessage: self.representedObject]];
//    }
// //    [[self.messageBodyViewContainer superview] replaceSubview: self.messageBodyViewContainer with: dataView];
//    NSTextContainer* tc = [dataView textContainer];
//    NSLayoutManager* lm = [tc layoutManager];
//    [lm glyphRangeForTextContainer: tc];
//    
//    CGFloat textHeight = [lm usedRectForTextContainer: tc].size.height;
// //    NSSize tcSize = [tc containerSize];
//    
// //    [tc setContainerSize: NSMakeSize(tcSize.width, textHeight+30)];
//    
//    if (self.messageBodyView) {
//        [self.messageBodyViewContainer replaceSubview: self.messageBodyView with: dataView];
//    } else {
//        [self.messageBodyViewContainer addSubview: dataView];
//    }
//    self.messageBodyView = dataView; // save for future use in replaceSubview:
//
//    NSLayoutPriority hcompRes = [dataView contentCompressionResistancePriorityForOrientation: NSLayoutConstraintOrientationVertical];
//    NSLayoutPriority vcompRes = [dataView contentCompressionResistancePriorityForOrientation: NSLayoutConstraintOrientationHorizontal];
//
//    NSDictionary *views = NSDictionaryOfVariableBindings(dataView, _messageBodyViewContainer);
//
//    [self.messageBodyViewContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[dataView]-0-|"
//                                                                   options:0
//                                                                   metrics:nil
//                                                                     views:views]];
//
//    [self.messageBodyViewContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[dataView]-0-|"
//                                                                        options:0
//                                                                        metrics:nil
//                                                                          views:views]];
//    
//    [dataView setContentCompressionResistancePriority: NSLayoutPriorityRequired forOrientation: NSLayoutConstraintOrientationVertical];
//    [self.messageBodyViewContainer setContentCompressionResistancePriority: NSLayoutPriorityRequired forOrientation: NSLayoutConstraintOrientationVertical];
//    
// //    [self.messageBodyViewContainer addSubview: dataView];
// //    [self.messageBodyViewContainer setFrame: [dataView frame]];
//    CGFloat finalMessageHeight = textHeight+headerHeight+40;
//    CGFloat originX = 0.0;
//    CGFloat originY = 0.0;
//    
//    NSRect vf = self.view.frame;
//    [self.view setFrame: NSMakeRect(originX, originY, vf.size.width, finalMessageHeight)];
// //    NSSize isize = [self.view fittingSize];
// //    [dataView setFrame: [(NSView*)self.messageBodyViewContainer frame]];
//    
//    [self.messageBodyViewContainer setNeedsDisplay: YES];
//}

-(NSAttributedString*) attributedStringFromMessage:(MBMessage *)message {
    NSMutableAttributedString* composition = [[NSMutableAttributedString alloc] initWithString: @"" attributes: nil];
    for (MBMime* node in message.childNodes) {
        NSAttributedString* subComposition = [node asAttributedStringWithOptions: nil attributes: nil];
        if (subComposition) {
            [composition appendAttributedString: subComposition];
        }
    }
    return [composition copy];
}


@end
