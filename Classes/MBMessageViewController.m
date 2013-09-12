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
#import "MBAddress+IMAP.h"

#import <QuartzCore/QuartzCore.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface MBMessageViewController ()

@property (weak) MBMime* rootChildNode;

@property (strong, nonatomic) NSArray* cachedOrderedMessageParts;

-(void) setEnvelopeFields;
-(NSString*) stringFromAddresses: (NSSet*) addresses;

@end

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

-(void) setMessage:(MBMessage *)message {
    if (message != _message) {
        _message = message;
        
        NSOrderedSet* rootNodes = _message.childNodes;
        NSInteger count = [rootNodes count];
        if (count > 0) {
            self.rootChildNode = [rootNodes objectAtIndex: 0];
            if (count>1) {
                DDLogCVerbose(@"[%@ %@] RootNode Count: %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), count);
            }
        }
    }
    [self setEnvelopeFields];
}
-(NSString*) stringFromAddresses:(NSSet *)addresses {
    NSMutableString* addressesAsString = [NSMutableString new];
    for (MBAddress* address in addresses) {
        if ([addresses isKindOfClass:[MBAddress class]]) {
            [addressesAsString appendString: [address stringRFC822AddressFormat]];
        }
    }
    return addressesAsString;
}
-(void) setEnvelopeFields {
    [self.subject setStringValue: self.message.subject];
    [self.sender setStringValue: [self stringFromAddresses: self.message.addressesTo]];
    [self.recipients setStringValue: [self.message.addressFrom stringRFC822AddressFormat]];
    [self.dateSent setObjectValue: self.message.dateSent];
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
    [self setEnvelopeFields];
    [self.outlineView reloadData];
}

#pragma mark - Outline Datasource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    MBMime* node = nil;
    
    if (!item) {
        node = self.rootChildNode;
    } else {
        if ([item isKindOfClass:[MBMime class]]) {
            node = [[(MBMime*)item childNodes] objectAtIndex: index];
        }
    }
    
    return node;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL expandable = NO;
    if (!item) {
        item = self.rootChildNode;
    }
    if ([item isKindOfClass:[MBMime class]]) {
        if ([[(MBMime*)item childNodes] count] > 0) {
            expandable = YES;
        }
    }

        return expandable;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger count = 0;
    
    if (!item) item = self.rootChildNode;
    
    if ([item isKindOfClass:[MBMime class]]) {
        count = [[(MBMime*)item childNodes] count];
    }
    
    return count;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id objectValue;
    
    if (!item) item = self.rootChildNode;
    
    if ([item isKindOfClass:[MBMime class]]) {
        if ([tableColumn.identifier isEqualToString: @"mimeName"]) {
            objectValue = [(MBMime*)item name];
            if (!objectValue) {
                objectValue = @"NoName";
            }
        } else if ([tableColumn.identifier isEqualToString: @"mimeType"]) {
            objectValue = [(MBMime*)item type];
        } else if ([tableColumn.identifier isEqualToString: @"mimeSubtype"]) {
            objectValue = [(MBMime*)item subtype];
        }
    }
    
    return objectValue;
}

#pragma mark - Outline Delegate

@end
