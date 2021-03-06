//
//  MBMessage+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 2/25/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBMessage+IntersectSetFix.h"
#import "NSManagedObject+Shortcuts.h"

@interface MBMessage (IMAP) //<NSCopying>

/*!
 Fetch the count for ALL messages in the passed context.
 
 @param moc NSManagedObjectContext in which to count the messages.
 
 @return the total unfiltered number of messages.
 */
+(NSUInteger) countInContext: (NSManagedObjectContext*) moc;

-(void) setPropertiesFromDictionary:(NSDictionary *)aDictionary;

-(void) setParsedSequence: (id) tokenized;
-(void) setParsedDateReceived: (id) tokenized;
-(void) setParsedDateSent: (id) tokenized;
-(void) setParsedMessageId: (id) tokenized;
-(void) setParsedAddressSender: (id) tokenized;
-(void) setParsedAddressFrom: (id) tokenized;
-(void) setParsedAddressReplyTo: (id) tokenized;
-(void) setParsedAddressesTo: (id) tokenized;
-(void) setParsedAddressesBcc: (id) tokenized;
-(void) setParsedAddressesCc: (id) tokenized;
-(void) setParsedFlags: (id) tokenized;
-(void) setParsedSubject: (id) tokenized;

-(void) setParsedOrganization: (id) tokenized;
-(void) setParsedReturnPath: (id) tokenized;
-(void) setParsedXSpamFlag: (id) tokenized;
-(void) setParsedXSpamLevel: (id) tokenized;
-(void) setParsedXSpamScore: (id) tokenized;
-(void) setParsedXSpamStatus: (id) tokenized;

-(void) setParsedSummary: (id) tokenized;
-(void) setParsedRfc2822size: (id) tokenized;
-(void) setParsedBodystructure: (id) tokenized;
-(void) setParsedBody: (id) tokenized;
-(void) setParsedEnvelope: (id) tokenized;

-(void) setFlag: (NSString*) flag;

-(NSArray*) attachments;
/*!
 Collate all of the mime parts\.
 Assumes all part data was populated by a fetch bodystructure.
 
 @return a set of mime parts.
 */
-(NSSet*) allMimeParts;
/*!
 Collate all of the mime parts which have content.
 Based on a part being a leaf. Assumes all part data was populated by a fetch bodystructure.
 
 @return a set of mime parts which have or need content.
 */
-(NSSet*) allMimeContentParts;
/*!
 Collate all of the mime parts which need content fetched.
 Based on a part being a leaf. Assumes all part data was populated by a fetch bodystructure.
 
 @return a set of mime parts which need content.
 */
-(NSSet*) allMimePartsMissingContent;

//-(NSArray*) childNodesArray;
//-(NSSet*) childNodesSet;

@end
