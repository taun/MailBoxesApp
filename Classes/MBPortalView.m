//
//  MBPortalView.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/05/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBPortalView.h"


@interface MBPortalView ()

-(void) setupStyle;

@end

@implementation MBPortalView


-(void) setupStyle {
    self.fillColor = [NSColor whiteColor];
    self.cornerRadius = HUD_CORNER_RADIUS;
    self.borderType = NSLineBorder;
    self.borderColor = [NSColor darkGrayColor];
    self.borderWidth = 1.0;
    [self setContentViewMargins: NSMakeSize(0, 0)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupStyle];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupStyle];
    }
    return self;
}


@end
