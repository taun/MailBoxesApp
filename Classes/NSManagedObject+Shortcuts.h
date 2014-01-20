//
//  NSManagedObject+Shortcuts.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Shortcuts)

+ (NSString *)entityName;
+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

@end
