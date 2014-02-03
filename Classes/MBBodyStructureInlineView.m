//
//  MBBodyStructureInlineView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/27/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBBodyStructureInlineView.h"
#import "MBMime+IMAP.h"

#import "MBMessagePlainView.h"

@interface MBBodyStructureInlineView ()

// quick and dirty, should use a view tag here or array
@property (nonatomic, strong) NSPointerArray* nodeViews;

-(void) setNodeView: (MBMimeView*) node atIndex: (NSUInteger) index;

-(void) createSubviews;
-(void) reloadData;

-(NSAttributedString*) attributedStringFromMessage: (MBMessage*) message;

@end

@implementation MBBodyStructureInlineView


-(void) awakeFromNib {
    [self createSubviews];
    [self addObserver: self forKeyPath: @"message" options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context: NULL];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"message"]) {
        [self reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) dealloc {
    [self removeObserver: self forKeyPath: @"message"];
}

-(void) setNodeView:(MBMimeView *)node atIndex:(NSUInteger)index {
    if (_nodeViews==nil) {
        _nodeViews = [NSPointerArray strongObjectsPointerArray];
    }
    if (index > _nodeViews.count) {
        _nodeViews.count = index;
    }
    [_nodeViews replacePointerAtIndex: index-1 withPointer: (__bridge void *)(node)];
}

-(void) updateConstraints {
    
    // last
    [super updateConstraints];
}

//-(void) viewWillStartLiveResize {
//    [super viewWillStartLiveResize];
//}

//-(void) viewDidEndLiveResize {
//    [super viewDidEndLiveResize];
//    [self removeConstraints: self.constraints];
//    [self.subTextView removeConstraints: self.subTextView.constraints];
//    [self setNeedsUpdateConstraints: YES];
//}

-(void) reloadData {
    MBMimeView* nodeView = [self.subviews objectAtIndex: 0];
    nodeView.node = [self.message.childNodes firstObject];
    [self setNeedsUpdateConstraints: YES];
}
/*!
 Need to replace the below with a self contained subview based on message components.
 */
-(void) createSubviews {
    NSSize subStructureSize = self.frame.size;
    NSRect nodeRect = NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height);
    MBMime* node = [[self.message childNodes] firstObject];
    MBMessagePlainView* nodeView = [[MBMessagePlainView alloc] initWithFrame: nodeRect node: node];
    
    [self setNodeView: nodeView atIndex: 1];
    
    [self addSubview: nodeView];
    
    [nodeView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    [self addConstraints:@[
                           [NSLayoutConstraint constraintWithItem: nodeView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant: 4],
                           
                           [NSLayoutConstraint constraintWithItem: nodeView
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                         constant: 4],
                           
                           [NSLayoutConstraint constraintWithItem: nodeView
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant: -4],
                           
                           [NSLayoutConstraint constraintWithItem: nodeView
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant: -4],
                           
                           ]];
    
    [nodeView setContentHuggingPriority: 240 forOrientation: NSLayoutConstraintOrientationHorizontal];
    [nodeView setContentHuggingPriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];

    [nodeView setContentCompressionResistancePriority: 240 forOrientation: NSLayoutConstraintOrientationHorizontal];
    [nodeView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
    
}


@end
