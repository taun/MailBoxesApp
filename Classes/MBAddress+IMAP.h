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

+ (MBAddress*) addressWithEmail: (NSString*) emailAddress 
                createIfMissing: (BOOL) create 
                        context: (NSManagedObjectContext*) context;

+ (MBAddress*) findAddressForEMail: (NSString *) emailAddress 
                           context: (NSManagedObjectContext*) context;


//+ (NSSet *) addressesFromCoreAddressSet: (NSSet *) coreAddressSet context: aContext;

@end
