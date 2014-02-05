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

@end

@implementation MBMessagePlainView

-(void) reloadData {
    
    NSDictionary* documentConversionAttributes = [NSDictionary new];
    NSAttributedString* subComposition;
    
    if (self.node.isDecoded && self.node.decoded) {
        subComposition = [[NSAttributedString alloc] initWithData: self.node.decoded options: nil documentAttributes: &documentConversionAttributes error: nil];
    }
    
    if (!subComposition) {
        subComposition = [[NSAttributedString alloc] initWithString: @"Loading..." attributes: self.attributes];
    }
    
    
    [[(NSTextView*)(self.mimeView) textStorage] setAttributedString: subComposition];
    [self setNeedsUpdateConstraints: YES];
}

-(void) createSubviews {
    NSSize subStructureSize = self.frame.size;
    
    NSTextView* nodeView = [[MDLTextViewIntrinsic alloc] initWithFrame: NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height)];
    // View in nib is min size. Therefore we can use nib dimensions as min when called from awakeFromNib
    [nodeView setMinSize: NSMakeSize(subStructureSize.width, subStructureSize.height)];
    [nodeView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [nodeView setVerticallyResizable: YES];
    
    // No horizontal scroll version
    //    [rawMime setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: NSViewWidthSizable];
    //
    //    [[rawMime textContainer] setContainerSize: NSMakeSize(subStructureSize.width, FLT_MAX)];
    //    [[rawMime textContainer] setWidthTracksTextView: YES];
    
    // Horizontal resizable version
    [nodeView setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
    
    [[nodeView textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [[nodeView textContainer] setWidthTracksTextView: YES];
    [self addSubview: nodeView];
    
    [nodeView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    //    NSDictionary *views = NSDictionaryOfVariableBindings(self, rawMime);
    
    //    [self setContentCompressionResistancePriority: NSLayoutPriorityFittingSizeCompression-1 forOrientation: NSLayoutConstraintOrientationVertical];
    //NSLayoutPriorityDefaultHigh
    [nodeView setWantsLayer: YES];
    CALayer* rawLayer = nodeView.layer;
    [rawLayer setBorderWidth: 2.0];
    [rawLayer setBorderColor: [[NSColor blueColor] CGColor]];
    
    
    CALayer* myLayer = self.layer;
    [myLayer setBorderWidth: 4.0];
    [myLayer setBorderColor: [[NSColor redColor] CGColor]];
    
    self.mimeView = nodeView;
    
    
   
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self.mimeView selector: @selector(viewFrameChanged:) name: NSViewFrameDidChangeNotification object: self.mimeView];
    
    [nodeView removeConstraints: nodeView.constraints];
    [self removeConstraints: self.constraints];
    [self setNeedsUpdateConstraints: YES];
}

-(void) dealloc {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self.mimeView];
}

@end
