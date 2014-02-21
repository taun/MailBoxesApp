//
//  MBMessagesDesktopView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/28/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesDesktopView.h"

static NSString *placeholderItem = nil;

@interface MBMessagesDesktopView ()

@property (nonatomic,strong) NSMutableArray     *items;

- (void) _removeItemsViews;

@end

@implementation MBMessagesDesktopView

+ (BOOL) requiresConstraintBasedLayout {
    return YES;
}


+ (void) initialize {
    placeholderItem = @"Placeholder";
}

//- (BOOL)translatesAutoresizingMaskIntoConstraints {
//    return NO;
//}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) awakeFromNib {
    if (self.boundController && self.contentBindingKeyPath) {
        [self bind: @"content" toObject: self.boundController withKeyPath: self.contentBindingKeyPath options: nil];
        if (self.selectionIndexesBindingKeyPath) {
            [self bind: @"selectionIndexes" toObject: self.boundController withKeyPath: self.selectionIndexesBindingKeyPath options: nil];
        }
        [self.boundController addObserver: self forKeyPath: self.contentBindingKeyPath options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context: NULL];
    }
    [self createSubviews];
}

-(void) dealloc {
    if (self.boundController && self.contentBindingKeyPath) {
        [self.boundController removeObserver: self forKeyPath: self.contentBindingKeyPath];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: self.contentBindingKeyPath]) {
        [self createSubviews];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(NSMutableArray*) items {
    if (_items == nil) {
        _items = [NSMutableArray new];
    }
    return _items;
}

- (void) updateConstraints {
    
//    if (self.items.count>0) {
//        NSCollectionViewItem *collectionItem = [self itemAtIndex: 0];
//        NSView *view = [collectionItem view];
//
//        [self addConstraints:@[
//                                    [NSLayoutConstraint constraintWithItem: self
//                                                                 attribute:NSLayoutAttributeTop
//                                                                 relatedBy:NSLayoutRelationEqual
//                                                                    toItem:view
//                                                                 attribute:NSLayoutAttributeTop
//                                                                multiplier:1.0
//                                                                  constant: 5],
//                                    
//                                    [NSLayoutConstraint constraintWithItem: self
//                                                                 attribute:NSLayoutAttributeLeft
//                                                                 relatedBy:NSLayoutRelationEqual
//                                                                    toItem:view
//                                                                 attribute:NSLayoutAttributeLeft
//                                                                multiplier:1.0
//                                                                  constant: 5],
//                                    
//                                    [NSLayoutConstraint constraintWithItem: self
//                                                                 attribute:NSLayoutAttributeRight
//                                                                 relatedBy:NSLayoutRelationEqual
//                                                                    toItem:view
//                                                                 attribute:NSLayoutAttributeRight
//                                                                multiplier:1.0
//                                                                  constant: 5],
//
//                                    [NSLayoutConstraint constraintWithItem: self
//                                                                 attribute:NSLayoutAttributeBottom
//                                                                 relatedBy:NSLayoutRelationEqual
//                                                                    toItem:view
//                                                                 attribute:NSLayoutAttributeBottom
//                                                                multiplier:1.0
//                                                                  constant: 10],
//                                    
//                                    
//                                    ]];
    
//        [view addConstraint: [NSLayoutConstraint constraintWithItem: view
//                                                          attribute:NSLayoutAttributeHeight
//                                                          relatedBy:NSLayoutRelationGreaterThanOrEqual
//                                                             toItem:nil
//                                                          attribute:NSLayoutAttributeNotAnAttribute
//                                                         multiplier:1
//                                                           constant: self.frame.size.height]];
//        
//        
//    }

    // last
//    [super updateConstraints];
    NSUInteger itemCount = self.items.count;
    NSMutableArray* collectionViews = [NSMutableArray arrayWithCapacity: itemCount];
    
    for (int i =0 ; i < itemCount ; i++) {
        NSCollectionViewItem *collectionItem = [self itemAtIndex: i];

        if (collectionItem) {
            [collectionViews addObject: [collectionItem view]];
        }
    }
    
    NSUInteger viewCount = collectionViews.count;

    if (viewCount > 0) {
        NSArray* views = [collectionViews copy];
        NSView* topView = views[0];
        NSView* bottomView = topView;
        
        NSMutableArray* constraints = [NSMutableArray new];
        // count is always 2+
        // need to set top most and bottom most boundaries to self.mimeView boundary
        // need to set inner boundaries equal to each other with a margin of X

        // set topView top constraints to container
        [constraints addObject: [NSLayoutConstraint constraintWithItem: topView
                                                             attribute: NSLayoutAttributeTop
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: self
                                                             attribute: NSLayoutAttributeTop
                                                            multiplier: 1.0
                                                              constant: 4]];
        

        int i = 0;
        while (i+1 < viewCount) {
            // If there is only one item, this never enters and bottomView still = topView
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
                                                                              constant: 4],
                                                [NSLayoutConstraint constraintWithItem: topView
                                                                             attribute: NSLayoutAttributeLeft
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self
                                                                             attribute: NSLayoutAttributeLeft
                                                                            multiplier: 1.0
                                                                              constant: 0],
                                                [NSLayoutConstraint constraintWithItem: topView
                                                                             attribute: NSLayoutAttributeRight
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self
                                                                             attribute: NSLayoutAttributeRight
                                                                            multiplier: 1.0
                                                                              constant: 0],
                                                ]];
            
            [topView setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
            [topView setContentHuggingPriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
            
            [topView setContentCompressionResistancePriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
            [topView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
            
            i++;
        }
        
        // set bottomView bottom constraints to container
        [constraints addObjectsFromArray: @[
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeBottom
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self
                                                                         attribute: NSLayoutAttributeBottom
                                                                        multiplier: 1.0
                                                                          constant: -4],
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeLeft
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self
                                                                         attribute: NSLayoutAttributeLeft
                                                                        multiplier: 1.0
                                                                          constant: 0],
                                            [NSLayoutConstraint constraintWithItem: bottomView
                                                                         attribute: NSLayoutAttributeRight
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self
                                                                         attribute: NSLayoutAttributeRight
                                                                        multiplier: 1.0
                                                                          constant: 0],
                                            ]];
        
        [bottomView setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
        [bottomView setContentHuggingPriority: 750 forOrientation: NSLayoutConstraintOrientationVertical];
        
        [bottomView setContentCompressionResistancePriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
        [bottomView setContentCompressionResistancePriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
        
        
        [self addConstraints: constraints];
    }
    [super updateConstraints];
}

/*
 Override this method if your custom view needs to perform custom layout not expressible using the constraint-based layout system. In this case you are responsible for calling setNeedsLayout: when something that impacts your custom layout changes.
 
 You may not invalidate any constraints as part of your layout phase, nor invalidate the layout of your superview or views outside of your view hierarchy. You also may not invoke a drawing pass as part of layout.
 
 You must call [super layout] as part of your implementation.
 */
- (void) layout {
    
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
//    // TODO: Implement "use Alternating Colors"
//    if (_backgroundColors && [_backgroundColors count] > 0)
//    {
//        NSColor *bgColor = [_backgroundColors objectAtIndex: 0];
//        [bgColor set];
//        NSRectFill(dirtyRect);
//    }
//    
//    NSPoint origin = dirtyRect.origin;
//    NSSize size = dirtyRect.size;
//    NSPoint oppositeOrigin = NSMakePoint (origin.x + size.width, origin.y + size.height);
//    
//    NSInteger firstIndexInRect = MAX(0, [self _indexAtPoint: origin]);
//    NSInteger lastIndexInRect = MIN([_items count] - 1, [self _indexAtPoint: oppositeOrigin]);
//    NSInteger index;
//    
//    for (index = firstIndexInRect; index <= lastIndexInRect; index++)
//    {
//        // Calling itemAtIndex: will eventually instantiate the collection view item,
//        // if it hasn't been done already.
//        NSCollectionViewItem *collectionItem = [self itemAtIndex: index];
//        NSView *view = [collectionItem view];
//        [view setFrame: [self frameForItemAtIndex: index]];
//    }
}

#pragma mark - CollectionView Imitation

- (void) setContent: (NSArray *)content {
    if (content != _content) {
        _content = content;
    }
    [self createSubviews];
}


- (NSCollectionViewItem *) newItemForRepresentedObject: (id)object {
    NSCollectionViewItem *collectionItem = nil;
    if (_itemPrototype) {
        collectionItem = [_itemPrototype copy];
        [collectionItem setRepresentedObject: object];
    }
    return collectionItem;
}

- (NSCollectionViewItem *) itemAtIndex: (NSUInteger)index {
    id item = [_items objectAtIndex: index];
    
    if (item == placeholderItem)
    {
        item = [self newItemForRepresentedObject: [_content objectAtIndex: index]];
        [_items replaceObjectAtIndex: index withObject: item];
        
        if ([[self selectionIndexes] containsIndex: index]) {
//            [item setSelected: YES];
        }
        
        [self addSubview: [item view]];
    }
    return item;
}

-(void) createSubviews {
    // maybe this should just be in updateConstraints?
    NSInteger i;
    
    [self _removeItemsViews];
    
    NSUInteger count = _content.count;
    for (i = 0; i < count; i++) {
        [self.items addObject: placeholderItem];
    }
    if (count > 0) {
        [self setNeedsUpdateConstraints: YES];
    }
    
//    if (self.itemPrototype) {
//        // Force recalculation of each item's frame
//        // set constraints here or ??
//        [self tile];
//    }
    // flag to make sure all of the constraints are applied to the new subViews
}

//- (void) resizeSubviewsWithOldSize: (NSSize)aSize
//{
//    NSSize currentSize = [self frame].size;
//    if (!NSEqualSizes(currentSize, aSize))
//    {
//        [self tile];
//    }
//}

- (void) _removeItemsViews
{
    if (_items!=nil) {
        
        for (id item in _items) {
            if ([item respondsToSelector: @selector(view)]) {
                
                [[item view] removeFromSuperview];
                [item setSelected: NO];
            }
        }
    
        [_items removeAllObjects];
        _items = nil;
    }
}


@end
