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
#import "MBMessage+IMAP.h"
#import "MBPortal.h"
#import "MBViewPortal.h"
#import "MBViewPortalSelection.h"
#import "MBTreeNode+IntersectsSetFix.h"
#import "MBox+Accessors.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface MBPortalViewController ()
@property (strong,nonatomic,readwrite)     NSArray         *messagesArray;
@property (strong,nonatomic,readwrite)     NSArray         *collectionItemSortDescriptors;
@property (strong,nonatomic,readwrite)     NSPredicate     *compoundPredicate;
@property (strong,nonatomic,readwrite)     NSSet           *selectedMessages;
@end

@implementation MBPortalViewController


CGFloat ONEROW = 18.0;

-(void) awakeFromNib {
    if (self.tableView) {
        [self.tableView setRowSizeStyle: NSTableViewRowSizeStyleCustom];
    }
    
    if (self.tableView && self.representedObject) {
        MBViewPortal* item = (MBViewPortal*) self.representedObject;
        
        CGFloat rowHeight = [item.rowHeight floatValue];
        [self.tableView setRowHeight: rowHeight];
    }
}

-(void) setRepresentedObject:(id)representedObject {
    
    [super setRepresentedObject:representedObject];

    if (representedObject) {
        [self addObserver: self forKeyPath: @"collectionView" options: NSKeyValueObservingOptionOld context: NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"collectionView"]) {
        //
        [self addObserver: self.collectionView forKeyPath: @"selectedMessages" options: NSKeyValueObservingOptionOld context: NULL];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)dealloc {
    [self removeObserver: self forKeyPath: @"collectionView"];
    [self removeObserver: self.collectionView forKeyPath: @"selectedMessages"];
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
    if (self.searchPredicate) {
        NSPredicate* results = [NSCompoundPredicate andPredicateWithSubpredicates: @[self.searchPredicate]];
        return results;
    }
    return nil;
            //[NSPredicate predicateWithFormat: [self valueForKeyPath: @"representedObject.predicateString"]], self.searchPredicate, nil]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(NSArray*) messagesArray {
    _messagesArray = Nil;
    MBViewPortal* item = (MBViewPortal*) self.representedObject;
    MBTreeNode* messagesNode = item.messageArraySource;
    if ([messagesNode respondsToSelector: NSSelectorFromString(@"messages")]) {
        _messagesArray = [messagesNode performSelector: NSSelectorFromString(@"messages")];
    }
    return _messagesArray;
}

#pragma clang diagnostic pop



#pragma mark -
#pragma mark Actions

-(void) contentUpdated {
    
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
    CGFloat newHeight = currentHeight + ONEROW;
    if (newHeight <= 6*ONEROW) {
        [self.tableView setRowHeight: currentHeight + ONEROW];
        MBViewPortal* item = (MBViewPortal*) self.representedObject;
        
        item.rowHeight = [NSNumber numberWithFloat: newHeight];
    }
//    [self.tableView setRowSizeStyle: [self changeSize: 1]];
}

- (IBAction)shrinkTableRows:(id)sender {
    CGFloat currentHeight = [self.tableView rowHeight];
//    [self.tableView setRowSizeStyle: [self changeSize: -1]];
    CGFloat newHeight = currentHeight - ONEROW;

    if (newHeight < 38) {
        newHeight = 38.0;
    }
    [self.tableView setRowHeight: newHeight];
    MBViewPortal* item = (MBViewPortal*) self.representedObject;
    
    item.rowHeight = [NSNumber numberWithFloat: newHeight];
}

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

/*
 Gets called any time a new row scrolls into view. Not relevant for adding a new element to the array.
 Just adding a row cell to the view.
 */
//- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
//    DDLogVerbose(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//}

@end
