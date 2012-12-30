//
//  MBCollectionViewItem.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/10/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MailBoxesAppDelegate.h"
#import "MBCollectionView.h"
#import "MBPortalViewController.h"
#import "MBMessage+IMAP.h"
#import "MBPortal.h"

@implementation MBPortalViewController

@synthesize messagesController;
@synthesize tableView;

@synthesize collectionItemSortDescriptors;
@synthesize compoundPredicate;
@synthesize searchPredicate;

CGFloat ONEROW = 18.0;




- (NSArray*) collectionItemSortDescriptors {
    if(collectionItemSortDescriptors == nil) {
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"dateSent" ascending:NO selector: @selector(compare:)];
        collectionItemSortDescriptors = [NSArray arrayWithObject: sort];
    }
    return collectionItemSortDescriptors;
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

-(NSPredicate *) compoundPredicate {
    return [NSCompoundPredicate andPredicateWithSubpredicates: 
            [NSArray arrayWithObjects: self.searchPredicate, nil]];    
            //[NSPredicate predicateWithFormat: [self valueForKeyPath: @"representedObject.predicateString"]], self.searchPredicate, nil]];    
}

#pragma mark -
#pragma mark Actions

- (NSTableViewRowSizeStyle) changeSize: (NSInteger) change {
    NSInteger rowSizeStyle = [self.tableView rowSizeStyle];
    NSTableViewRowSizeStyle newSizeStyle = NSTableViewRowSizeStyleMedium;
    
    if (change > 0) {
        // increment
        if (rowSizeStyle== NSTableViewRowSizeStyleMedium) {
            newSizeStyle = NSTableViewRowSizeStyleLarge;
        } else if (rowSizeStyle == NSTableViewRowSizeStyleLarge) {
            newSizeStyle = NSTableViewRowSizeStyleLarge;
        }
    } else {
        //decrement
        if (rowSizeStyle == NSTableViewRowSizeStyleMedium) {
            newSizeStyle = NSTableViewRowSizeStyleSmall;
        } else if (rowSizeStyle == NSTableViewRowSizeStyleSmall) {
            newSizeStyle = NSTableViewRowSizeStyleSmall;
        }
    }
    return newSizeStyle;
}

- (IBAction)growTableRows:(id)sender {
    //CGFloat currentHeight = [tableView rowHeight];
    //[tableView setRowHeight: currentHeight + ONEROW];   
    //[tableView setRowSizeStyle: [self changeSize: 1]];
}

- (IBAction)shrinkTableRows:(id)sender {
    //CGFloat currentHeight = [tableView rowHeight];
    //[tableView setRowSizeStyle: [self changeSize: -1]];

    //if (currentHeight >= (2*ONEROW)) {
    //    [tableView setRowHeight: currentHeight - ONEROW];
    //}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Bold the text in the selected items, and unbold non-selected items
    [self.tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        // Enumerate all the views, and find the NSTableCellViews. This demo could hard-code things, as it knows that the first cell is always an NSTableCellView, but it is better to have more abstract code that works in more locations.
        for (NSInteger column = 0; column < rowView.numberOfColumns; column++) {
            NSView *cellView = [rowView viewAtColumn:column];
            // Is this an NSTableCellView?
            if ([cellView isKindOfClass:[NSTableCellView class]]) {
                NSTableCellView *tableCellView = (NSTableCellView *)cellView;
                // It is -- grab the text field and bold the font if selected
                NSTextField *textField = tableCellView.textField;
                NSInteger fontSize = [textField.font pointSize];
                if (rowView.selected) {
                    textField.font = [NSFont boldSystemFontOfSize:fontSize];
                    //
                } else {
                    textField.font = [NSFont systemFontOfSize:fontSize];
                }
            }
        }
    }];
    MailBoxesAppDelegate *app = (MailBoxesAppDelegate *)[[NSApplication sharedApplication] delegate];
    MBMessage *selectedMessage = (MBMessage *)[[self.messagesController arrangedObjects] objectAtIndex: [self.tableView selectedRow]];
    [app showSelectedMessage: selectedMessage];
    MBCollectionView *cv = (MBCollectionView *)app.collectionView;
    [cv setSelectionIndexes: [NSIndexSet indexSetWithIndex: [[cv subviews] indexOfObject: [self view]]]];
}

- (void)dealloc {
    [tableView setDelegate: nil];
}

@end
