//
//  MBAddress+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAddress+IMAP.h"

@implementation MBAddress (IMAP)

+ (NSString *)entityName {
    return @"MBAddress";
}

+ (instancetype)newAddressWithEmail:(NSString *)email
                createIfMissing:(BOOL)create  
                        context: (NSManagedObjectContext*) context{
    
    MBAddress *theAddress = nil;
    
    if (email) {
        theAddress = [MBAddress findAddressForEMail: email context: context];
        
        if (theAddress == nil && create) {
            // address was not found and needs to be created
            theAddress = [MBAddress insertNewObjectIntoContext: context];
            
            theAddress.email = email;
        }
    }
    
    return theAddress;
}

+ (instancetype) findAddressForEMail: (NSString *) email context: (NSManagedObjectContext*) context {
    MBAddress * address = nil;
    if (email) {
        
        NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
        
        __block NSError *error = nil;
        
        NSDictionary *substitutionDictionary = 
        @{@"EMAIL": email};
        
        NSFetchRequest *fetchRequest = 
        [model fetchRequestFromTemplateWithName:@"MBAddressForEmail"
                          substitutionVariables:substitutionDictionary];
        
        NSArray *fetchedObjects;
        
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];        
        
        // ToDo deal with error
        // There should always be only one. Don't know what error to post if > 1
        if ( ([fetchedObjects count] == 1) ) {
            address = fetchedObjects[0];
        }
    }
    
    return address;
}

-(NSString *) stringRFC822AddressFormat {
    NSString *rfc822Email = nil;
    if (self.name.length != 0) {
        rfc822Email = [NSString stringWithFormat: @"%@ <%@>", self.name, self.email];
    } else {
        rfc822Email = [NSString stringWithFormat: @"<%@>", self.email];
    }
    return rfc822Email;
}


//+ (NSSet *) addressesFromCoreAddressSet: (NSSet *) coreAddressSet context: aContext {
//    NSInteger count = [coreAddressSet count];
//    NSMutableSet *addressEntities = [[NSMutableSet alloc] initWithCapacity: count];
//    
//    for(CTCoreAddress *coreAddress in coreAddressSet) {
//        MBAddress *address = [NSEntityDescription
//                              insertNewObjectForEntityForName:@"MBAddress"
//                              inManagedObjectContext: aContext];
//        address.email = [coreAddress email];
//        
//        if ( ([coreAddress name] == nil) || ([[coreAddress name] length] < 1) ){
//            address.name = @"";
//        }
//        else {
//            address.name = [coreAddress name];            
//        }
//        [addressEntities addObject: address];
//        [address release];
//    }
//    return addressEntities;
//}

@end
