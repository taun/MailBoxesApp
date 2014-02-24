//
//  MBTreeNode.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBTreeNode, MBViewPortal;

@interface MBTreeNode : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSNumber * isLeaf;
@property (nonatomic, retain) NSNumber * isOwner;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *childNodes;
@property (nonatomic, retain) NSSet *contentViews;
@property (nonatomic, retain) NSOrderedSet *parentNodes;
@end

@interface MBTreeNode (CoreDataGeneratedAccessors)

- (void)insertObject:(MBTreeNode *)value inChildNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildNodesAtIndex:(NSUInteger)idx;
- (void)insertChildNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildNodesAtIndex:(NSUInteger)idx withObject:(MBTreeNode *)value;
- (void)replaceChildNodesAtIndexes:(NSIndexSet *)indexes withChildNodes:(NSArray *)values;
- (void)addChildNodesObject:(MBTreeNode *)value;
- (void)removeChildNodesObject:(MBTreeNode *)value;
- (void)addChildNodes:(NSOrderedSet *)values;
- (void)removeChildNodes:(NSOrderedSet *)values;
- (void)addContentViewsObject:(MBViewPortal *)value;
- (void)removeContentViewsObject:(MBViewPortal *)value;
- (void)addContentViews:(NSSet *)values;
- (void)removeContentViews:(NSSet *)values;

- (void)insertObject:(MBTreeNode *)value inParentNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromParentNodesAtIndex:(NSUInteger)idx;
- (void)insertParentNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeParentNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInParentNodesAtIndex:(NSUInteger)idx withObject:(MBTreeNode *)value;
- (void)replaceParentNodesAtIndexes:(NSIndexSet *)indexes withParentNodes:(NSArray *)values;
- (void)addParentNodesObject:(MBTreeNode *)value;
- (void)removeParentNodesObject:(MBTreeNode *)value;
- (void)addParentNodes:(NSOrderedSet *)values;
- (void)removeParentNodes:(NSOrderedSet *)values;
@end
