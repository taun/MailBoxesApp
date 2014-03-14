//
//  MBMimeParameter+Shorthand.m
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMimeParameter+Shorthand.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBMimeParameter (Shorthand)


+ (NSString *)entityName {
    return @"MBMimeParameter";
}

+ (instancetype) newParameterWithName: (NSString*) aName
                                value: (NSString*) aValue
                              context: (NSManagedObjectContext*) context {
    
    MBMimeParameter *parameter = nil;
    
    if (aName && aValue) {
        
        parameter = [MBMimeParameter insertNewObjectIntoContext: context];
        if (parameter) {
            parameter.name = aName;
            parameter.value = aValue;
        }
    }
    
    return parameter;
}

+ (NSArray*) findParameterForName: (NSString*) aName
                                value: (NSString*) aValue
                              context: (NSManagedObjectContext*) context {
    
    NSArray* parameters;
    
    if (aName && aValue) {
        
        NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
        
        __block NSError *error = nil;
        
        NSDictionary *substitutionDictionary =
        @{@"NAME": aName, @"VALUE": aValue};
        
        NSFetchRequest *fetchRequest =
        [model fetchRequestFromTemplateWithName:@"MBMParamNameValueFetch"
                          substitutionVariables:substitutionDictionary];
        
        parameters = [context executeFetchRequest:fetchRequest error:&error];
        
        // ToDo deal with error
        // There should always be only one. Don't know what error to post if > 1
     }
    
    return parameters;
}

@end
