//
//  MBAddress+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAddress+IMAP.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBAddress (IMAP)

+ (NSString *)entityName {
    return @"MBAddress";
}

+(instancetype) newAddressFromSimpleAddress:(SimpleRFC822Address *)address inContext:(NSManagedObjectContext *)moc {
    MBAddress *theAddress = nil;
    
    if (address.email) {
        theAddress = [self newAddressWithName: address.name Email: address.email createIfMissing: YES context: moc];
    } else {
        // group or just list
        theAddress = [MBAddress insertNewObjectIntoContext: moc];
        theAddress.name = address.name;
        NSMutableSet* subAddresses = [[NSMutableSet alloc] initWithCapacity: address.addresses.count];
        for (SimpleRFC822Address* subAddress in address.addresses) {
            //
            MBAddress* newSubMBAddress = [MBAddress newAddressFromSimpleAddress: subAddress inContext: moc];
            if (newSubMBAddress) {
                [subAddresses addObject: newSubMBAddress];
            }
        }
        [theAddress setChildNodes: [subAddresses copy]];
    }
    
    return theAddress;
}

+(instancetype) newAddressWithEmail:(NSString *)emailAddress
                    createIfMissing:(BOOL)create
                            context:(NSManagedObjectContext *)context {
    return [[self class] newAddressWithName: @"" Email: emailAddress createIfMissing: create context: context];
}

+(instancetype)newAddressWithName: (NSString*) name
                             Email:(NSString *)email
                   createIfMissing:(BOOL)create
                           context: (NSManagedObjectContext*) context{
    
    MBAddress *theAddress = nil;
    
    if (email) {
        theAddress = [MBAddress findAddressForEMail: email context: context];
        
        if (theAddress == nil && create) {
            // address was not found and needs to be created
            theAddress = [MBAddress insertNewObjectIntoContext: context];
            
            theAddress.email = email;
            if ([name isNonNilString]) {
                theAddress.name = name;
            }
        }
    }
    
    return theAddress;
}

+(instancetype) findAddressForEMail: (NSString *) email context: (NSManagedObjectContext*) context {
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

-(SimpleRFC822Address*) newSimpleAddress {
    SimpleRFC822Address* newAddress;

    if (self.email) {
        // leaf
        newAddress = [SimpleRFC822Address new];
        newAddress.name = self.name;
        newAddress.email = self.email;
        // should be no addresses
    } else {
        // group
        newAddress = [SimpleRFC822Address new];
        newAddress.name = self.name;
        NSMutableSet* addressSet = [[NSMutableSet alloc] initWithCapacity: self.childNodes.count];
        
        for (MBAddress* childNode in self.childNodes) {
            SimpleRFC822Address* newChildAddress = [childNode newSimpleAddress];
            if (newChildAddress) {
                [addressSet addObject: newChildAddress];
            }
        }
        newAddress.addresses = addressSet;
    }
    
    return newAddress;
}



@end
