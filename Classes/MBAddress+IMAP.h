//
//  MBAddress+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBAddress.h"

#import <MoedaeMailPlugins/SimpleRFC822Address.h>
#import <MoedaeMailPlugins/NSObject+MBShorthand.h>

/*!
 This should be renamed to MBAddressStore. All of the CoreData classes should be Stores.
 */
@interface MBAddress (IMAP)

+(instancetype) newAddressFromSimpleAddress: (SimpleRFC822Address*)address
                                  inContext: (NSManagedObjectContext*) moc;

+(instancetype) newAddressWithName: (NSString*) name
                             Email: (NSString*) emailAddress
                    createIfMissing: (BOOL) create
                            context: (NSManagedObjectContext*) context;

+(instancetype) newAddressWithEmail: (NSString*) emailAddress
                    createIfMissing: (BOOL) create
                            context: (NSManagedObjectContext*) context;

+(instancetype) findAddressForEMail: (NSString *) emailAddress
                            context: (NSManagedObjectContext*) context;

-(SimpleRFC822Address*) newSimpleAddress;

//+ (NSSet *) addressesFromCoreAddressSet: (NSSet *) coreAddressSet context: aContext;

@end
