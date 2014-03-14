//
//  MBAddress+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBAddress.h"
#import "NSManagedObject+Shortcuts.h"

@interface MBAddress (IMAP)

+ (instancetype) newAddressWithEmail: (NSString*) emailAddress
                createIfMissing: (BOOL) create 
                        context: (NSManagedObjectContext*) context;

+ (instancetype) findAddressForEMail: (NSString *) emailAddress
                           context: (NSManagedObjectContext*) context;

-(NSString *) stringRFC822AddressFormat;
//+ (NSSet *) addressesFromCoreAddressSet: (NSSet *) coreAddressSet context: aContext;

@end
