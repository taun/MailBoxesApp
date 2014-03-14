//
//  MBMimeDisposition.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBDispositionParameter, MBMime;

@interface MBMimeDisposition : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) MBMime *mime;
@property (nonatomic, retain) NSSet *parameters;
@end

@interface MBMimeDisposition (CoreDataGeneratedAccessors)

- (void)addParametersObject:(MBDispositionParameter *)value;
- (void)removeParametersObject:(MBDispositionParameter *)value;
- (void)addParameters:(NSSet *)values;
- (void)removeParameters:(NSSet *)values;

@end
