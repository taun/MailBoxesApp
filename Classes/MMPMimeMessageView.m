//
//  MMPMimeMessageView.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MMPMimeMessageView.h"
#import "MailBoxesAppDelegate.h"

#import "MMPMimeHeaderView.h"

#import "MBMimeMessage+IMAP.h"
#import "MBMessage+IMAP.h"

@implementation MMPMimeMessageView



+(NSSet*) contentTypes {
    return [NSSet setWithObjects: @"MESSAGE/RFC822", nil];
}

/*
 Need to create a subview PER subpart.
 
 How to layout views?
 Linear vertically, horizontally, tiled?
 
 Create a container view.
 Add subviews to container view with appropriate constraints.
 
 Show an attachment as a horizontal bar with actions rather than box?
 
 */
-(void) createSubviews {
    NSSize subStructureSize = self.frame.size;
    NSRect nodeRect = NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height);

    // node should only ever have one childNode
    // mimeView is xib messageView
    // subViews go in bodyStructureView
    // pass node to messageView and it handles above notes.
    // all this view does is set node and set constraints for messageView, maybe outline messageView?
    //    self.messageView.node = [self.node.childNodes firstObject];
    
    self.mimeView = [[NSView alloc] initWithFrame: nodeRect];

    MMPBaseMimeView* headerView = [[MMPMimeHeaderView alloc] initWithFrame: nodeRect node: self.node options: self.options];
    [headerView setTranslatesAutoresizingMaskIntoConstraints: NO];
    [self.mimeView addSubview: headerView]; // replace with header view
    
    
    for (MMPMimeProxy* subNode in self.node.childNodes) {
        Class nodeViewClass = [[MBMimeViewerPluginsManager manager] classForMimeType: subNode.type subtype: subNode.subtype];
        
        MMPBaseMimeView* nodeView = [[nodeViewClass alloc] initWithFrame: nodeRect node: subNode options: self.options];
        [nodeView setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        [self.mimeView addSubview: nodeView];
    }
    
    // Enclose the sub message in a box
    CGFloat borderWidth = 1.0;
    CGFloat borderRadius = 6.0;
    CALayer* rawLayer;

    [self.mimeView setWantsLayer: YES];
    rawLayer = self.mimeView.layer;
    rawLayer.borderColor = [[NSColor grayColor] CGColor];
    rawLayer.borderWidth = borderWidth;
    rawLayer.cornerRadius = borderRadius;

//    if (self.options.showViewOutlines) {
//
//        [headerView setWantsLayer: YES];
//        rawLayer = headerView.layer;
//        rawLayer.borderColor = [[NSColor grayColor] CGColor];
//        rawLayer.BorderWidth = borderWidth;
//        rawLayer.cornerRadius = borderRadius;
//    }
    
    
//    [self.headerView setWantsLayer: YES];
//    rawLayer = self.headerView.layer;
//    [rawLayer setBorderWidth: borderWidth];
//    [rawLayer setBorderColor: [[NSColor greenColor] CGColor]];
    
//    [self setWantsLayer: YES];
//    CALayer* myLayer = self.layer;
//    [myLayer setBorderWidth: borderWidth*2];
//    [myLayer setBorderColor: [[NSColor redColor] CGColor]];
    
    [super createSubviews];
}

/*
 
 
 
 
 */
-(void) updateConstraints  {
    NSUInteger count = self.mimeView.subviews.count;
    
    if (count >= 2) {
        NSArray* views = self.mimeView.subviews;
        NSView* topView;
        NSView* bottomView;
        
        NSMutableArray* constraints = [NSMutableArray new];
        // count is always 2+
        // need to set top most and bottom most boundaries to self.mimeView boundary
        // need to set inner boundaries equal to each other with a margin of X
        topView = views[0];
        // set topView top constraints to container
        [constraints addObject: [NSLayoutConstraint constraintWithItem: topView
                                                             attribute: NSLayoutAttributeTop
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: self.mimeView
                                                             attribute: NSLayoutAttributeTop
                                                            multiplier: 1.0
                                                              constant: self.constraintVMargin]];
        
        
        for (int i = 0; i < (count-1) ; i++) {
            //
            topView = views[i];
            bottomView = views[i+1];
            
            // always set middle
            // set topView bottom to bottomView top
            [constraints addObjectsFromArray: @[
                                                [NSLayoutConstraint constraintWithItem: topView
                                                                             attribute: NSLayoutAttributeBottom
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: bottomView
                                                                             attribute: NSLayoutAttributeTop
                                                                            multiplier: 1.0
                                                                              constant: self.constraintVMargin],
                                                [NSLayoutConstraint constraintWithItem: topView
                                                                             attribute: NSLayoutAttributeLeft
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.mimeView
                                                                             attribute: NSLayoutAttributeLeft
                                                                            multiplier: 1.0
                                                                              constant: 0],
                                                [NSLayoutConstraint constraintWithItem: topView
                                                                             attribute: NSLayoutAttributeRight
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.mimeView
                                                                             attribute: NSLayoutAttributeRight
                                                                            multiplier: 1.0
                                                                              constant: 0],
                                                ]];
            
            [topView setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
            [topView setContentHuggingPriority: self.options.verticalHuggingPriority forOrientation: NSLayoutConstraintOrientationVertical];
            
            [topView setContentCompressionResistancePriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
            [topView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
            
        }
        
        bottomView = [views lastObject];
        // set bottomView bottom constraints to container
        [constraints addObjectsFromArray: @[
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeBottom
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.mimeView
                                                                         attribute: NSLayoutAttributeBottom
                                                                        multiplier: 1.0
                                                                          constant: -self.constraintVMargin],
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeLeft
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.mimeView
                                                                         attribute: NSLayoutAttributeLeft
                                                                        multiplier: 1.0
                                                                          constant: 0],
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeRight
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.mimeView
                                                                         attribute: NSLayoutAttributeRight
                                                                        multiplier: 1.0
                                                                          constant: 0],
                                            ]];
        
        [bottomView setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
        [bottomView setContentHuggingPriority: self.options.verticalHuggingPriority forOrientation: NSLayoutConstraintOrientationVertical];
        
        [bottomView setContentCompressionResistancePriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
        [bottomView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
        
        
        [self.mimeView addConstraints: constraints];
    }
    
    [super updateConstraints];
}

@end
