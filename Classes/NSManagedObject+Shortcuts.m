//
//  NSManagedObject+Shortcuts.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "NSManagedObject+Shortcuts.h"

@implementation NSManagedObject (Shortcuts)

+ (NSString *)entityName {
    return @"NSManagedObject";
}

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
}

@end
