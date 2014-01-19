//
//  MBMessageView.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMessageView.h"

@implementation MBMessageView

+(BOOL) requiresConstraintBasedLayout {
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

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void) awakeFromNib {
    [self setBoxType: NSBoxCustom];
    [self setCornerRadius: 5.0];
    [self setFillColor: [NSColor whiteColor]];
    [self setBorderColor: [NSColor grayColor]];
    [self setBorderWidth: 2.0];
    [self setTitlePosition: NSNoTitle];
}


@end
