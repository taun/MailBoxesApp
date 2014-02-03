//
//  MBMessagePlainView.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMessagePlainView.h"
#import "MDLTextViewIntrinsic.h"

@interface MBMessagePlainView ()

@property (nonatomic,strong) NSTextView     *subTextView;

@end

@implementation MBMessagePlainView

-(void) reloadData {
    NSAttributedString* subComposition = [self.node asAttributedStringWithOptions: self.options attributes: self.attributes];
    [[self.subTextView textStorage] setAttributedString: subComposition];
    [self setNeedsLayout: YES];
    [self setNeedsUpdateConstraints: YES];
}

-(void) createSubviews {
    NSSize subStructureSize = self.frame.size;
    
    NSTextView* rawMime = [[MDLTextViewIntrinsic alloc] initWithFrame: NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height)];
    // View in nib is min size. Therefore we can use nib dimensions as min when called from awakeFromNib
    [rawMime setMinSize: NSMakeSize(subStructureSize.width, subStructureSize.height)];
    [rawMime setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [rawMime setVerticallyResizable: YES];
    
    // No horizontal scroll version
    //    [rawMime setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: NSViewWidthSizable];
    //
    //    [[rawMime textContainer] setContainerSize: NSMakeSize(subStructureSize.width, FLT_MAX)];
    //    [[rawMime textContainer] setWidthTracksTextView: YES];
    
    // Horizontal resizable version
    [rawMime setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
    
    [[rawMime textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [[rawMime textContainer] setWidthTracksTextView: YES];
    [self addSubview: rawMime];
    
    [rawMime setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    //    NSDictionary *views = NSDictionaryOfVariableBindings(self, rawMime);
    
    //    [self setContentCompressionResistancePriority: NSLayoutPriorityFittingSizeCompression-1 forOrientation: NSLayoutConstraintOrientationVertical];
    //NSLayoutPriorityDefaultHigh
    [rawMime setWantsLayer: YES];
    CALayer* rawLayer = rawMime.layer;
    [rawLayer setBorderWidth: 2.0];
    [rawLayer setBorderColor: [[NSColor blueColor] CGColor]];
    
    
    CALayer* myLayer = self.layer;
    [myLayer setBorderWidth: 4.0];
    [myLayer setBorderColor: [[NSColor redColor] CGColor]];
    
    self.subTextView = rawMime;
    
    [self addConstraints:@[
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant: 4],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                         constant: 4],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant: -4],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant: -4],
                           
                           ]];
    
    NSView* nodeView = self.subTextView;
    [nodeView setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
    [nodeView setContentHuggingPriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
    
    [nodeView setContentCompressionResistancePriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
    [nodeView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
    
   
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self.subTextView selector: @selector(viewFrameChanged:) name: NSViewFrameDidChangeNotification object: self.subTextView];
}

-(void) dealloc {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self.subTextView];
}

@end
