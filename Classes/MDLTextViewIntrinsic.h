//
//  MDLTextViewIntrinsic.h
//  ConstraintsTests
//
//  Created by Taun Chapman on 01/30/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 SubClass to help NSTextView play nice with Autolayout.
 
 Sets the intrinsicContentSize height to the frame height.
 
 Leaves the width as NSViewNoInstrinsicMetric
 */
@interface MDLTextViewIntrinsic : NSTextView

-(void) viewFrameChanged: (NSView*) view;

-(void) viewBoundsChanged: (NSView*) view;

@end
