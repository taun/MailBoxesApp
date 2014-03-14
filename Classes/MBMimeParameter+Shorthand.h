//
//  MBMimeParameter+Shorthand.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMimeParameter.h"

@interface MBMimeParameter (Shorthand)

+ (instancetype) newParameterWithName: (NSString*) aName
                                value: (NSString*) aValue
                              context: (NSManagedObjectContext*) context;

+ (NSArray*) findParameterForName: (NSString*) aName
                                value: (NSString*) aValue
                              context: (NSManagedObjectContext*) context;

@end
