//
//  MBBodyStructureInlineView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/27/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBBodyStructureInlineView.h"
#import "MBMime+IMAP.h"

#import <MoedaeMailPlugins/MoedaeMailPlugins.h>

@interface MBBodyStructureInlineView ()

@property (nonatomic,strong) MBMessage* message;

// quick and dirty, should use a view tag here or array
@property (nonatomic, strong) NSPointerArray* nodeViews;

-(void) setNodeView: (MMPBaseMimeView*) node atIndex: (NSUInteger) index;

-(void) removeSubviews;
-(void) createSubviews;

@end

@implementation MBBodyStructureInlineView


-(void) awakeFromNib {
//    [self addObserver: self forKeyPath: @"message" options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context: NULL];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"message"]) {
//        if (self.message) {
//            [self createSubviews];
//            [self reloadData];
//        }
    } else if ([keyPath isEqualToString: @"isFullyCached"]) {
        // Message parts are downloaded on demand on a background thread.
        // Need to reload the view data if the parts are updated/downloaded
        if ([self.message.isFullyCached boolValue] == YES) {
            [self reloadViews];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) dealloc {
//    [self removeObserver: self forKeyPath: @"message"];
    [self.message removeObserver: self forKeyPath: @"isFullyCached"];
}

-(void) setMessage:(MBMessage *)message {
    if (_message != message) {
        [self removeSubviews];
        [_message removeObserver: self forKeyPath: @"isFullyCached"];
        
        _message = message;
        
        [self createSubviews];
        [self setNeedsUpdateConstraints: YES];
        [_message addObserver: self forKeyPath: @"isFullyCached" options: (NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context: NULL];
    }
}

-(void) setMessage:(MBMessage *)message options:(MMPMessageViewOptions *)options {
    // order is important. Should rewrite so it isn't be but is.
    self.options = options;
    // setting message should go last due to message observer
    self.message = message;
}


-(void) setNodeView:(MMPBaseMimeView *)node atIndex:(NSUInteger)index {
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

-(void) reloadViews {
    [self removeSubviews];
    [self createSubviews];
}

-(void) removeSubviews {
    for (NSView* view in self.nodeViews) {
        if (view != NULL) {
            [view removeFromSuperview];
        }
    }
}

#pragma message "ToDo: create a placeholder default plugin for when one isn't available for the mime type"
/*!
 Need to replace the below with a self contained subview based on message components.
 */
-(void) createSubviews {

    NSSize subStructureSize = self.frame.size;
    NSRect nodeRect = NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height);
    MMPMimeProxy* node = [[[self.message childNodes] firstObject] asMimeProxy];
    
    Class nodeViewClass = [[MBMimeViewerPluginsManager manager] classForMimeType: node.type subtype: node.subtype];
    
    MMPBaseMimeView* nodeView = [[nodeViewClass alloc] initWithFrame: nodeRect node: node options: self.options];
    
    if (nodeView) {
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
}


@end
