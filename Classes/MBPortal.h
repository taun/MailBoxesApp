//
//  MBPortal.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBSmartFolder, MBUser;

@interface MBPortal : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) id predicate;
@property (nonatomic, retain) NSString * predicateString;
@property (nonatomic, retain) NSSet *criteria;
@property (nonatomic, retain) MBUser *parentNode;
@end

@interface MBPortal (CoreDataGeneratedAccessors)

- (void)addCriteriaObject:(MBSmartFolder *)value;
- (void)removeCriteriaObject:(MBSmartFolder *)value;
- (void)addCriteria:(NSSet *)values;
- (void)removeCriteria:(NSSet *)values;

@end
