//
//  MBMessagesCollectionView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/28/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesCollectionView.h"

@implementation MBMessagesCollectionView

+ (BOOL) requiresConstraintBasedLayout {
    return YES;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) awakeFromNib {
    
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
    NSCollectionViewItem* newItem = [super newItemForRepresentedObject:object];
    return newItem;
}

- (void) updateConstraints {
    
    // last
    [super updateConstraints];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
