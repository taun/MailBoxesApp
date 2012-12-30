//
//  MBMime.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMessage, MBMime, MBMimeData, MBMimeDisposition, MBMimeParameter;

@interface MBMime : NSManagedObject

@property (nonatomic, retain) NSString * bodyIndex;
@property (nonatomic, retain) NSString * charset;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * encoding;
@property (nonatomic, retain) NSString * extensions;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSNumber * isAttachment;
@property (nonatomic, retain) NSNumber * isInline;
@property (nonatomic, retain) NSNumber * isLeaf;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSNumber * lines;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * md5;
@property (nonatomic, retain) NSString * mime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * octets;
@property (nonatomic, retain) NSString * subtype;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * subPartNumber;
@property (nonatomic, retain) NSOrderedSet *childNodes;
@property (nonatomic, retain) MBMimeData *data;
@property (nonatomic, retain) MBMimeDisposition *disposition;
@property (nonatomic, retain) MBMessage *message;
@property (nonatomic, retain) MBMessage *messageReference;
@property (nonatomic, retain) NSSet *parameters;
@property (nonatomic, retain) MBMime *parentNode;
@end

@interface MBMime (CoreDataGeneratedAccessors)

- (void)insertObject:(MBMime *)value inChildNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildNodesAtIndex:(NSUInteger)idx;
- (void)insertChildNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildNodesAtIndex:(NSUInteger)idx withObject:(MBMime *)value;
- (void)replaceChildNodesAtIndexes:(NSIndexSet *)indexes withChildNodes:(NSArray *)values;
- (void)addChildNodesObject:(MBMime *)value;
- (void)removeChildNodesObject:(MBMime *)value;
- (void)addChildNodes:(NSOrderedSet *)values;
- (void)removeChildNodes:(NSOrderedSet *)values;
- (void)addParametersObject:(MBMimeParameter *)value;
- (void)removeParametersObject:(MBMimeParameter *)value;
- (void)addParameters:(NSSet *)values;
- (void)removeParameters:(NSSet *)values;

@end
