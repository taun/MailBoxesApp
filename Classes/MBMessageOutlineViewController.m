//
//  MBMessageOutlineViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/29/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMessageOutlineViewController.h"
#import "MBMessage+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMimeImage+IMAP.h"
#import "MBMimeData+IMAP.h"
#import "MBMultiAlternative.h"
#import "MBAddress+IMAP.h"
#import "MBMessageView.h"
#import "MBMessageHeaderView.h"


#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface MBMessageOutlineViewController ()

@property (strong, nonatomic) NSArray* cachedOrderedMessageParts;

-(void) setEnvelopeFields;
-(NSAttributedString*) attributedStringFromMessage: (MBMessage*) message;

@end

@implementation MBMessageOutlineViewController


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

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString: @"defaultContent"]) {
        [self refreshMessageDisplay: nil];
    } else if ([keyPath isEqualToString: @"data"]) {
        [self displayNode: object];
    }
    
}

-(void) setMessage:(MBMessage *)message {
    if (message != _message) {
        if (_message != nil) {
            //            [_message removeObserver: self forKeyPath: @"defaultContent"];
            if (self.outlineView.selectedRow > -1) {
                MBMime* previousSelectedNode = [self.outlineView itemAtRow: [self.outlineView selectedRow]];
                [previousSelectedNode removeObserver: self forKeyPath: @"data"];
            }
        }
        _message = message;
        //        [_message addObserver: self forKeyPath: @"defaultContent" options: NSKeyValueObservingOptionNew context: NULL];
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
    [self setEnvelopeFields];
    [self.outlineView reloadData];
    [self.outlineView expandItem: nil expandChildren: YES];
    
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

#pragma mark - Outline Datasource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    MBMime* node = nil;
    
    if (!item) {
        node = (self.message.childNodes)[index];
    } else {
        if ([item isKindOfClass:[MBMime class]]) {
            node = [(MBMime*)item childNodes][index];
        }
    }
    
    return node;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL expandable = NO;
    if ([item isKindOfClass:[MBMime class]]) {
        if ([[(MBMime*)item childNodes] count] > 0) {
            expandable = YES;
        }
    }
    
    return expandable;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger count = 0;
    
    if (!item) {
        count = [self.message.childNodes count];
    } else {
        if ([item isKindOfClass:[MBMime class]]) {
            count = [[(MBMime*)item childNodes] count];
        }
    }
    
    
    return count;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id objectValue;
    
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
        } else if ([tableColumn.identifier isEqualToString: @"mimeIsAttachment"]) {
            objectValue = [(MBMime*)item isAttachment];
        } else if ([tableColumn.identifier isEqualToString: @"mimeIsInline"]) {
            objectValue = [(MBMime*)item isInline];
        }
    }
    
    return objectValue;
}

#pragma mark - Outline Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    BOOL shouldSelect = YES;
    if ([item isKindOfClass:[MBMultiAlternative class]]) {
        shouldSelect = NO;
    }
    
    if (shouldSelect && (self.outlineView.selectedRow > -1)) {
        MBMime* previousSelectedNode = [self.outlineView itemAtRow: [self.outlineView selectedRow]];
        [previousSelectedNode removeObserver: self forKeyPath: @"data"];
    }
    return shouldSelect;
}
-(void) displayNode: (MBMime*) node {
    NSData* messageData = [node getDecodedData];
    
    id dataView;
    dataView = [NSTextView new];
    //NSLayoutManager* layoutManager = [dataView layoutManager];
    //[layoutManager addTextContainer: nil];
    
    [dataView setEditable: NO];
    [dataView setHorizontallyResizable: YES];
    [dataView setVerticallyResizable: YES];
    [dataView setString: @"Loading....."];
    
    if (!messageData) {
        [dataView setString: @"No Data"];
    } else {
        if ([node.subtype isEqualToString: @"HTML"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[dataView textStorage] setAttributedString: [[NSAttributedString alloc] initWithHTML: messageData documentAttributes: nil]];
            });
        } else if ([node.subtype isEqualToString: @"ENRICHED"]) {
            [[dataView textStorage] setAttributedString: [[NSAttributedString alloc] initWithData: messageData options: nil documentAttributes: nil error: nil]];
        } else if ([node.type isEqualToString: @"APPLICATION"]) {
            if ([node.subtype isEqualToString: @"PDF"]) {
                // Use PDF Kit
                PDFView* pdfView = [PDFView new];
                [pdfView setAutoScales: YES];
                [pdfView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
                [pdfView setFrame: NSMakeRect(0, 0, 900, 900)];
                
                PDFDocument* document = [[PDFDocument alloc] initWithData: messageData];
                [pdfView setDocument: document];
                dataView = pdfView;
            } else if ([node.subtype isEqualToString: @"MSWORD"]) {
                NSAttributedString* wordString = [[NSAttributedString alloc] initWithDocFormat: messageData documentAttributes: nil];
                [[dataView textStorage] setAttributedString: wordString];
            }
            
        } else if ([node.type isEqualToString: @"IMAGE"]) {
            [[dataView textStorage] setAttributedString:  [node asAttributedStringWithOptions:nil attributes:nil]];
        } else {
            [[dataView textStorage] setAttributedString: [node asAttributedStringWithOptions: nil attributes: nil]] ;
        }
    }
#pragma message "need to add timer for isSeenFlag AND save flag status."
    MBMessage* message = node.messageReference;
    message.isSeenFlag = @YES;
    
    [self.messageBodyViewContainer addSubview: dataView];
    [self.messageBodyViewContainer setNeedsDisplay: YES];
}
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    MBMime* node = [self.outlineView itemAtRow: [self.outlineView selectedRow]];
    [node addObserver: self forKeyPath: @"data" options: NSKeyValueObservingOptionNew context: NULL];
    [self displayNode: node];
}

@end
