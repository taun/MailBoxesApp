//
//  MBMimeDisposition.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/8/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMime, MBMimeParameter;

@interface MBMimeDisposition : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) MBMime *mime;
@property (nonatomic, retain) NSSet *parameters;
@end

@interface MBMimeDisposition (CoreDataGeneratedAccessors)

- (void)addParametersObject:(MBMimeParameter *)value;
- (void)removeParametersObject:(MBMimeParameter *)value;
- (void)addParameters:(NSSet *)values;
- (void)removeParameters:(NSSet *)values;

@end
