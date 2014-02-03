//
//  MBMimeView.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/29/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeView.h"

static NSString *   kDataKeyPath   = @"data";

@implementation MBMimeView

-(void) setNode:(MBMime *)node {
    if (_node != node) {
        [_node removeObserver: self forKeyPath: kDataKeyPath];
        _node = node;
        [self reloadData];
        [_node addObserver: self forKeyPath: kDataKeyPath options: (NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context: NULL];
    }
}

-(instancetype) initWithFrame:(NSRect)frameRect node:(MBMime *)node {
    self = [super initWithFrame: frameRect];
    if (self) {
        // Initialization code here.
        [self setNode: node];
        [self createSubviews];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    return [self initWithFrame: frame node: nil];
}

-(void) dealloc {
    [_node removeObserver: self forKeyPath: kDataKeyPath];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString: kDataKeyPath]) {
        [self reloadData];
    }
    
}

-(void) createSubviews {
    
}

-(void) reloadData {
    
}


@end
