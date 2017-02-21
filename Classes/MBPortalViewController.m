//
//  MBCollectionViewItem.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/10/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MailBoxesAppDelegate.h"
#import "MBPortalsCollectionView.h"
#import "MBPortalViewController.h"
#import "MBPortalView.h"

#import "MBTreeNode+IntersectsSetFix.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBAddress+IMAP.h"
#import "MBAccount+IMAP.h"

#import "MBMime+IMAP.h"
#import "MBMimeData+IMAP.h"

#import "MBViewPortal+Extra.h"
#import "MBViewPortalMBox+Extra.h"
#import "MBViewPortalSelection+Extra.h"
#import "MBViewPortalSmartFolder+Extra.h"

#import "MBAccountsCoordinator.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface MBPortalViewController ()
@property (strong,nonatomic,readwrite)     NSArray         *messagesArray;
@property (strong,nonatomic,readwrite)     NSArray         *collectionItemSortDescriptors;
@property (strong,nonatomic,readwrite)     NSPredicate     *compoundPredicate;
@property (strong,nonatomic,readwrite)     NSSet           *selectedMessages;

@property (assign,nonatomic,readonly)     CGFloat         oneRowHeight;
@property (assign,nonatomic,readonly)     CGFloat         cellBaseHeight;
@property (assign,nonatomic,readonly)     CGFloat         cellMaxRows;

@end

@implementation MBPortalViewController


-(void) awakeFromNib {
    if (self.tableView) {
        [self.tableView setRowSizeStyle: NSTableViewRowSizeStyleCustom];
    }
    
    _cellMaxRows = 6.0;
    
    NSTextFieldCell* summaryCell = self.messageSummaryField.cell;

    if (summaryCell) {
        CGFloat totalHeight = self.tableView.rowHeight;
        CGFloat summaryHeight = self.messageSummaryField.bounds.size.height;
        
        _cellBaseHeight = totalHeight - summaryHeight;
        _oneRowHeight = summaryCell.cellSize.height;
    }
    
    if (self.tableView && self.representedObject) {
        MBViewPortal* item = (MBViewPortal*) self.representedObject;
        
        CGFloat rowHeight = [item.rowHeight floatValue];
        
        if (rowHeight < (_cellBaseHeight+_oneRowHeight) || rowHeight > (_cellBaseHeight+_cellMaxRows*_oneRowHeight)) {
            rowHeight = fmaxf(_cellBaseHeight + 2*_oneRowHeight,44.0);
        }
        
        [self.tableView setRowHeight: rowHeight];
    }
    
    if (self.labelUnderline) {
        NSColor* defaultColor = [[NSColor lightGrayColor] colorWithAlphaComponent: 0]; // hide for now may use later
        [self.labelUnderline setBoxType: NSBoxCustom];
        [self.labelUnderline setBorderType: NSLineBorder];
        [self.labelUnderline setBorderColor: defaultColor];
        [self.labelUnderline setFillColor: defaultColor];
        
        NSRect boxFrame = self.labelUnderline.frame;
        CGFloat newHeight = 2.0;
        CGFloat newOriginY = boxFrame.origin.y + boxFrame.size.height/2 - newHeight/2.0;
        [self.labelUnderline setFrame: NSMakeRect(boxFrame.origin.x, newOriginY, boxFrame.size.width, newHeight)];
    }
}

-(void) setRepresentedObject:(id)representedObject {
    
    [super setRepresentedObject:representedObject];

    if (representedObject) {
        [self addObserver: self forKeyPath: @"collectionView" options: NSKeyValueObservingOptionOld context: NULL];
        MBViewPortal* item = (MBViewPortal*) self.representedObject;
        
//        [item updateItemsList];

        NSColor* boxColor = item.color;
        if (boxColor && [boxColor isKindOfClass: [NSColor class]]) {
            MBPortalView* pview = [[self.view subviews] firstObject];
            if (pview) {
                [self changePortal: pview toColor: boxColor];
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"collectionView"]) {
        //becomeFirstResponder
        [self addObserver: self.collectionView forKeyPath: @"selectedMessages" options: NSKeyValueObservingOptionOld context: NULL];
//        [self addObserver: self.collectionView forKeyPath: @"selected" options: NSKeyValueObservingOptionOld context: NULL];
//        [self addObserver: self.collectionView forKeyPath: @"becomeFirstResponder" options: NSKeyValueObservingOptionOld context: NULL];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)dealloc {
    [self removeObserver: self forKeyPath: @"collectionView"];
    [self removeObserver: self.collectionView forKeyPath: @"selectedMessages"];
//    [self removeObserver: self.collectionView forKeyPath: @"selected"];
//    [self removeObserver: self.collectionView forKeyPath: @"becomeFirstResponder"];
    [_tableView setDelegate: nil];
}


- (NSArray*) collectionItemSortDescriptors {
    if(_collectionItemSortDescriptors == nil) {
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"dateSent" ascending:NO selector: @selector(compare:)];
        _collectionItemSortDescriptors = @[sort];
    }
    return _collectionItemSortDescriptors;
}

#pragma mark -
#pragma mark Predicate

/*!
 @method keyPathsForValuesAffectingCompoundPredicate
 
 @discussion
    Need to combine the predicate from the search box and the portal definition which
    means needing to monitor both for changes then update the compoundPredicate.
 
 @result set of ...

 */
+(NSSet *) keyPathsForValuesAffectingCompoundPredicate{
    return [NSSet setWithObjects: @"searchPredicate", @"representedObject.predicateString" , nil];
}
+(NSSet *) keyPathsForValuesAffectingMessagesArray{
    return [NSSet setWithObjects: @"representedObject.messageArraySource" , nil];
}
/*
 Bound to the messagesController.
 Doesn't do anything yet?
 
 */
-(NSPredicate *) compoundPredicate {
    NSPredicate* results = nil;
    
#pragma message "ToDo: make showing or hiding deleted messages a user preference."
    NSPredicate* removeDeletedMessages = [NSPredicate predicateWithFormat:@"isDeletedFlag == NO"];
    NSPredicate* removeSubmessages = [NSPredicate predicateWithFormat:@"parentMessage == nil"];
    
    if (self.searchPredicate) {
        // Deleted messages re-appear (on purpose) during search.
        results = [NSCompoundPredicate andPredicateWithSubpredicates: @[self.searchPredicate]];
    } else {
        results = [NSCompoundPredicate andPredicateWithSubpredicates: @[removeDeletedMessages,removeSubmessages]];
    }
    return results;
            //[NSPredicate predicateWithFormat: [self valueForKeyPath: @"representedObject.predicateString"]], self.searchPredicate, nil]];
}


#pragma mark -
#pragma mark Actions

-(void) contentUpdated {
    
}
-(void) changePortal: (MBPortalView*) pview toColor: (NSColor*) newColor {
    if (pview) {
        CGFloat hue;
        CGFloat saturation;
        CGFloat brightness;
        CGFloat alpha;
        [newColor getHue: &hue saturation: &saturation brightness: &brightness alpha: &alpha];
        
        NSColor* brightColor = [NSColor colorWithDeviceHue: hue saturation: saturation brightness: brightness alpha: alpha];
        NSColor* lowColor = [NSColor colorWithDeviceHue: hue saturation: 0.1 brightness: brightness alpha: alpha];
        [pview setBorderColor: brightColor];
//        [pview setFillColor: lowColor];
//        [self.labelUnderline setBorderColor: alphaColor];
//        [self.labelUnderline setFillColor: alphaColor];
    }
}
- (IBAction)changePortalColor:(id)sender {
    MBViewPortal* item = (MBViewPortal*) self.representedObject;
    MBPortalView* pview = [[self.view subviews] firstObject];
    if (pview) {
        NSColor* newColor = [NSColor redColor];
        [self changePortal: pview toColor: newColor];
        [item setColor: newColor];
//        [self.labelUnderline setBorderColor: alphaColor];
    }
}

- (IBAction)togglePortalControls:(id)sender {
    if (self.portalSearchView.isHidden) {
        [self.portalSearchView setHidden: NO];
        [self.portalSearchView setContentCompressionResistancePriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
        [self.portalRowPlusView setHidden: NO];
        [self.portalRowPlusView setContentCompressionResistancePriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
        [self.portalRowMinusView setHidden: NO];
        [self.portalRowMinusView setContentCompressionResistancePriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
    } else {
        [self.labelUnderline setHidden: YES];
        [self.portalSearchView setHidden: YES];
        [self.portalSearchView setContentCompressionResistancePriority: 1 forOrientation: NSLayoutConstraintOrientationVertical];
        [self.portalRowPlusView setHidden: YES];
        [self.portalRowPlusView setContentCompressionResistancePriority: 1 forOrientation: NSLayoutConstraintOrientationVertical];
        [self.portalRowMinusView setHidden: YES];
        [self.portalRowMinusView setContentCompressionResistancePriority: 1 forOrientation: NSLayoutConstraintOrientationVertical];
    }
}

//- (NSTableViewRowSizeStyle) changeSize: (NSInteger) change {
//    NSInteger rowSizeStyle = [self.tableView rowSizeStyle];
//    NSTableViewRowSizeStyle newSizeStyle = NSTableViewRowSizeStyleMedium;
//    
//    if (change > 0) {
//        // increment
//        if (rowSizeStyle== NSTableViewRowSizeStyleMedium) {
//            newSizeStyle = NSTableViewRowSizeStyleLarge;
//        } else if (rowSizeStyle == NSTableViewRowSizeStyleLarge) {
//            newSizeStyle = NSTableViewRowSizeStyleLarge;
//        }
//    } else {
//        //decrement
//        if (rowSizeStyle == NSTableViewRowSizeStyleMedium) {
//            newSizeStyle = NSTableViewRowSizeStyleSmall;
//        } else if (rowSizeStyle == NSTableViewRowSizeStyleSmall) {
//            newSizeStyle = NSTableViewRowSizeStyleSmall;
//        }
//    }
//    return newSizeStyle;
//}

- (IBAction)growTableRows:(id)sender {
    CGFloat currentHeight = [self.tableView rowHeight];
    CGFloat newHeight = currentHeight + self.oneRowHeight;
    if (newHeight <= (self.cellBaseHeight+self.cellMaxRows*self.oneRowHeight)) {
        [self.tableView setRowHeight: currentHeight + self.oneRowHeight];
        MBViewPortal* item = (MBViewPortal*) self.representedObject;
        
        item.rowHeight = [NSNumber numberWithFloat: newHeight];
    }
//    [self.tableView setRowSizeStyle: [self changeSize: 1]];
}

- (IBAction)shrinkTableRows:(id)sender {
    CGFloat currentHeight = [self.tableView rowHeight];
//    [self.tableView setRowSizeStyle: [self changeSize: -1]];
    CGFloat newHeight = currentHeight - self.oneRowHeight;

    if (newHeight < self.cellBaseHeight) {
        newHeight = self.cellBaseHeight;
    }
    [self.tableView setRowHeight: newHeight];
    MBViewPortal* item = (MBViewPortal*) self.representedObject;
    
    item.rowHeight = [NSNumber numberWithFloat: newHeight];
}

- (IBAction)reloadMessageBody:(id)sender {
    NSInteger index = [self.tableView selectedRow];
    if (index >= 0) {
        //
        MBMessage *selectedMessage = (MBMessage *)[self.messagesController arrangedObjects][index];
        // MBMessageViewController only tries to update messages with isFullyCached == NO
        selectedMessage.isFullyCached = @NO;
        for (MBMime* mime in selectedMessage.allMimeContentParts) {
            if (mime.data) {
                // IMAPClient only loads mime parts where data == nil
                mime.data = nil;
            }
        }
    }
}

- (IBAction)logAddresses:(id)sender {
    NSInteger index = [self.tableView selectedRow];
    if (index >= 0) {
        //
        MBMessage *selectedMessage = (MBMessage *)[self.messagesController arrangedObjects][index];
        // MBMessageViewController only tries to update messages with isFullyCached == NO
        for (MBAddress* address in selectedMessage.addressesTo) {
            DDLogVerbose(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), address);
        }
    }
}

#pragma mark - TableViewDelegate

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    DDLogVerbose(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), rowView);
}

/*
 Could change this from watching the table selection to
 binding the MBPortalsCollectionView to the ArrayController.selectedObjects
 have an array of properties for each portal ArrayController and watch selectedObjects
 
 or add observer for ArrayController.selectedObjects rather than viewController.selectedMessages
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Bold the text in the selected items, and unbold non-selected items
//    [self.tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
//        // Enumerate all the views, and find the NSTableCellViews. This demo could hard-code things, as it knows that the first cell is always an NSTableCellView, but it is better to have more abstract code that works in more locations.
//        for (NSInteger column = 0; column < rowView.numberOfColumns; column++) {
//            NSView *cellView = [rowView viewAtColumn:column];
//            // Is this an NSTableCellView?
//            if ([cellView isKindOfClass:[NSTableCellView class]]) {
//                NSTableCellView *tableCellView = (NSTableCellView *)cellView;
//                // It is -- grab the text field and bold the font if selected
//                NSTextField *textField = tableCellView.textField;
//                NSInteger fontSize = [textField.font pointSize];
//                if (rowView.selected) {
//                    textField.font = [NSFont boldSystemFontOfSize:fontSize];
//                    //
//                } else {
//                    textField.font = [NSFont systemFontOfSize:fontSize];
//                }
//            }
//        }
//    }];

    NSIndexSet* selectedRows = [self.tableView selectedRowIndexes];
    
    NSMutableSet* messages = [NSMutableSet new];
    NSUInteger index=[selectedRows firstIndex];
    while(index != NSNotFound)
    {
        
        MBMessage *selectedMessage = (MBMessage *)[self.messagesController arrangedObjects][index];
        [messages addObject: selectedMessage];
        index=[selectedRows indexGreaterThanIndex: index];
    }
    
    self.selectedMessages = [messages copy];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    DDLogVerbose(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), row);
    return nil;
}


/*
 Gets called any time a new row scrolls into view. Not relevant for adding a new element to the array.
 Just adding a row cell to the view.
 */
//- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
//    DDLogVerbose(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//}

@end
