//
//  MBMessage+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 2/25/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessage+IMAP.h"
#import "MBAddress+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMimeDisposition+Shorthand.h"
#import "MBDispositionParameter+Shorthand.h"
#import "MBMimeParameter+Shorthand.h"
#import "NSManagedObject+Shortcuts.h"

#import "MBMimeMulti.h"
#import "MBMultiMixed+IMAP.h"
#import "MBMultiAlternative+IMAP.h"
#import "MBMultiParallel.h"
#import "MBMultiRelated.h"
#import "MBMultiSigned.h"
#import "MBMimeMessage.h"
#import "MBMultiEncrypted.h"
#import "MBMultiDigest.h"

#import "MBMimeMedia.h"
#import "MBMimeApplication+IMAP.h"
#import "MBMimeAudio.h"
#import "MBMimeImage+IMAP.h"
#import "MBMimeText+IMAP.h"
#import "MBMimeVideo.h"

#import "MBMimeData+IMAP.h"

#import "MBTokenTree.h"

#import <MoedaeMailPlugins/SimpleRFC822Address.h>
#import <MoedaeMailPlugins/NSString+IMAPConversions.h>
#import <MoedaeMailPlugins/NSDate+IMAPConversions.h>

#import "MBSimpleRFC822AddressToStringTransformer.h"
#import "MBSimpleRFC822AddressSetToStringTransformer.h"

#include <time.h>
#include <xlocale.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

//static const int ddLogLevel = LOG_LEVEL_WARN;
static const int ddLogLevel = LOG_LEVEL_INFO;


@interface MBMessage (ConvenienceTransformers)


/*!
 a multi part composite mime
 contains either a leaf part or a multi part
 
 @param parts MBTokenTree
 */
-(MBMime*) unpackCompositeMimeFrom: (MBTokenTree*) parts;

/*!
 a composite mime message/rfc822
 contains either a leaf part or a multi part
 
 @param parts MBTokenTree
 */
-(MBMime*) unpackSubMessageMimeFrom: (MBTokenTree*) parts;

/*!
 a composite mime envelope
 
 @param parts MBTokenTree
 */
-(MBMime*) unpackIMAPEnvelopeFrom: (MBTokenTree*) parts;

/*!
 leaf content of a multi part
 
 @param part MBTokenTree
 */
-(MBMime*) unpackDiscreteMimeFrom: (MBTokenTree*) part;

/*!
 parameters are just key value pairs.
 
 @param tokens MBTokenTree
 */
-(NSSet*) unpackParametersOfClass: (Class) aClass fromNextToken: (MBTokenTree*) tokens;

-(MBMimeDisposition*) unpackDispositionFromNextToken: (MBTokenTree*) tokens;

/*!
 Called once after parsing a bodystructure to traverse the mime tree and assign the appropriate IMAP body index.
 
 @param topLevel Node to traverse.
 @param path The path index array as strings or nil if just starting.
 @param rIndex Recursion index to stop runaway recursion.
 */
- (void) generateBodyIndexes: (MBMime*) topLevel path: (NSArray*) path rIndex: (NSUInteger) rIndex;

-(MBAddress*) checkAddress: (id) token;

-(NSString*) checkAnd2047DecodeToken: (id) token;
-(NSDate*) checkAndDecodeTokenAsDate: (id) token;

@end

@implementation MBMessage (IMAP)

//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
//    
//    BOOL automatic = NO;
//    if ([theKey isEqualToString:@"defaultContent"]) {
//        automatic = NO;
//    }
//    else {
//        automatic = [super automaticallyNotifiesObserversForKey:theKey];
//    }
//    return automatic;
//}

+ (NSString *)entityName {
    return @"MBMessage";
}

+(NSUInteger) countInContext: (NSManagedObjectContext*) moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName: [MBMessage entityName] inManagedObjectContext: moc]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [moc countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        //Handle error
    }
    return count;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) setPropertiesFromDictionary:(NSDictionary *)aDictionary {
            
        for (id aKey in aDictionary) {
            NSString* method;
            
            id aValue = aDictionary[aKey];
            method = [NSString stringWithFormat: @"setParsed%@:",aKey];
            [self performSelector: NSSelectorFromString(method) withObject: aValue];
        }
}

#pragma clang diagnostic pop


-(void) setParsedSequence: (id) tokenized {
    NSNumber* sequence = nil;
    
    if ([tokenized isKindOfClass: [NSString class]]) {
        NSString* sequenceString = tokenized;
        
        sequence = @([sequenceString longLongValue]);
        
    } else if ([tokenized isKindOfClass: [NSNumber class]]) {
        sequence = tokenized;
    }
    self.sequence = sequence;
}
-(void) setParsedRfc2822size: (id) tokenized {
    NSNumber* rfc2822Size = nil;
    
    if (tokenized != nil && [tokenized isKindOfClass: [NSString class]]) {
        NSString* rfc2822SizeString = tokenized;
        
        rfc2822Size = @([rfc2822SizeString longLongValue]);
        
    } else if ([tokenized isKindOfClass: [NSNumber class]]) {
        rfc2822Size = tokenized;
    }
    self.rfc2822Size = rfc2822Size;
}
-(void) setParsedDateReceived: (id) tokenized {
    self.dateReceived = [self checkAndDecodeTokenAsDate: tokenized];
}
-(void) setParsedDateSent: (id) tokenized {
    self.dateSent = [self checkAndDecodeTokenAsDate: tokenized];
}
-(void) setParsedAddressSender: (id) tokenized {

    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressSender: mbAddresses];
    }
}
-(void) setParsedAddressFrom: (id) tokenized {

    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressFrom: mbAddresses];
    }
}
-(void) setParsedAddressReplyTo: (id) tokenized {

    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressReplyTo: mbAddresses];
    }
}

-(MBAddress*) parseAddressTokens: (id) tokenized {
    DDLogVerbose(@"[%@ %@: %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tokenized);
    
    SimpleRFC822Address* simpleAddress;
    MBAddress* topLevelPersistentAddress;
    
    if (tokenized != nil && [tokenized isKindOfClass: [NSString class]]) {
        
        simpleAddress = [SimpleRFC822Address newFromString: tokenized];
        
        topLevelPersistentAddress = [MBAddress newAddressFromSimpleAddress: simpleAddress inContext: self.managedObjectContext];
        
    } else if (tokenized != nil && [tokenized isKindOfClass: [MBTokenTree class]]) {
        
        topLevelPersistentAddress = [self parseEnvelopeAddressTokens: tokenized];
    }
    return topLevelPersistentAddress;
}
-(MBAddress*) parseEnvelopeAddressTokens: (MBTokenTree*) tokenized {
    SimpleRFC822Address* simpleAddress;
    MBAddress* topLevelPersistentAddress;
    
    // we will convert to a string then to an address since all of the group parsing logic is already working from a string
    // and it is more trivial to convert to a string than redo the group and address logic here.
    NSMutableString* addressesString = [NSMutableString new];
    BOOL previousPassWasAddress = NO;
    
    for (NSArray* envelopeAddress in tokenized.tokenArray) {
        //
        
        if ([envelopeAddress isKindOfClass: [NSArray class]] && envelopeAddress.count == 4) {
            // correct argument
            // address structure are in the following order: personal name, [SMTP] at-domain-list (source route), mailbox name, and host name.
            // group syntax is indicated by a special form of address structure in which the host name field is NIL.
            if ([envelopeAddress[3] isNonNilString]) {
                // normal address
                if (previousPassWasAddress) [addressesString appendString: @","];
                [addressesString appendFormat: @"\"%@\" <%@@%@>",envelopeAddress[0],envelopeAddress[2],envelopeAddress[3]];

                previousPassWasAddress = YES;
            } else if (![envelopeAddress[3] isNonNilString] && [envelopeAddress[0] isNonNilString]) {
                // start of group
                if (previousPassWasAddress) [addressesString appendString: @", "];
                [addressesString appendFormat: @"%@:",envelopeAddress[0]];
                previousPassWasAddress = NO;
            } else if (![envelopeAddress[3] isNonNilString] && ![envelopeAddress[0] isNonNilString]) {
                // end of group
                [addressesString appendFormat: @";"];
                previousPassWasAddress = NO;
            }
        } else {
            // something wrong
            DDLogError(@"[%@ %@: Should have an array with 4 strings, instead we have: %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tokenized);
        }
        if ([addressesString isNonNilString]) {
            simpleAddress = [SimpleRFC822Address newFromString: addressesString];
            topLevelPersistentAddress = [MBAddress newAddressFromSimpleAddress: simpleAddress inContext: self.managedObjectContext];
        }
    }
    return topLevelPersistentAddress;
}
/*
 "Nancy Reigel" <ndreigel@bellatlantic.net>, "'Carl Davies'" <carl_davies99@yahoo.com>, "'Taun'" <taun@charcoalia.net>, "'Michael B. Parmet'" <mbparmet@parmetech.com>, <geminikc9@yahoo.com>, <richard.hankin@hankingroup.com>, <DBoscher@CNTUS.JNJ.COM>, <mark@mccay.com>, <canniff@canniff.net>, <ndreigel@verizon.net>, <monckma@yahoo.com>, "'Alicia Shultz'" <AliciaShultz@princetowncable.com>, "'Laurie'" <reelmom5@verizon.net>, "'Wagner, Tim [NCSUS]'" <twagner@ncsus.jnj.com>, <jppsd@msn.com>, <karen_vanbemmel@yahoo.com>
*/
-(void) setParsedAddressesTo: (id) tokenized {
    
    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressesTo: mbAddresses];
    }
}
-(void) setParsedAddressesBcc: (id) tokenized {
    
    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressesBcc: mbAddresses];
    }
}
-(void) setParsedAddressesCc: (id) tokenized {
    
    MBAddress* mbAddresses = [self parseAddressTokens: tokenized];
    
    if (mbAddresses) {
        [self setAddressesCc: mbAddresses];
    }
}
-(void) setParsedMessageId: (id) tokenized {
    if (tokenized != nil && [tokenized isKindOfClass: [NSString class]]) {
        self.messageId = (NSString*) tokenized;
    }
}
-(void) setParsedSubject: (id) tokenized {
    self.subject = [self checkAnd2047DecodeToken: tokenized];
}

-(void) setParsedOrganization: (id) tokenized {
    self.organization = [self checkAnd2047DecodeToken: tokenized];
}

-(void) setParsedReturnPath: (id) tokenized {
    self.returnPath = [self checkAnd2047DecodeToken: tokenized];
}

-(void) setParsedXSpamFlag: (id) tokenized {
    NSNumber* spamFlag = @NO;
    
    if ([[tokenized uppercaseString] isEqualToString: @"YES"]) {
        spamFlag = @YES;
    }
    self.xSpamFlag = spamFlag;
}

-(void) setParsedXSpamLevel: (id) tokenized {
    self.xSpamLevel = tokenized;
}

-(void) setParsedXSpamScore: (id) tokenized {
    NSNumber* score = nil;
    
    if (tokenized != nil && [tokenized isKindOfClass: [NSString class]]) {
        NSString* scoreString = tokenized;
        
        score = [NSNumber numberWithFloat: [scoreString floatValue]];
        
    } else if ([tokenized isKindOfClass: [NSNumber class]]) {
        score = tokenized;
    }
    [self setXSpamScore: score];
}
-(void) setParsedXSpamStatus: (id) tokenized {
    self.xSpamStatus = tokenized;
}

-(void) setParsedSummary: (id) tokenized {
//    self.summary = [self checkAnd2047DecodeToken: tokenized];
//    self.summary = tokenized;
}
-(void) setParsedFlags: (id) tokenized {
    for (id token in tokenized) {
        [self setFlag: token];
    }
}
-(void) setFlag:(NSString *)flag {
    if (flag != nil && [flag isKindOfClass: [NSString class]]) {
        // Handle standard flags
        NSString* lowercaseFlag = [flag lowercaseString];
        if ([lowercaseFlag isEqualToString: @"\\seen"]) {
            self.isSeenFlag = @YES;
        } else if ([lowercaseFlag isEqualToString: @"\\answered"]) {
            self.isAnsweredFlag = @YES;
        } else if ([lowercaseFlag isEqualToString: @"\\flagged"]) {
            self.isFlaggedFlag = @YES;
        } else if ([lowercaseFlag isEqualToString: @"\\deleted"]) {
            self.isDeletedFlag = @YES;
        } else if ([lowercaseFlag isEqualToString: @"\\draft"]) {
            self.isDraftFlag = @YES;
        } else if ([lowercaseFlag isEqualToString: @"\\recent"]) {
            self.isRecentFlag = @YES;
        }
    }
}
#pragma message "ToDo: check performance of looping for part vs fetch request for part"
/*!
 dictionary key: "body" object (part#, data)
 
 Need to find the body part then assign the data
 
 @param tokenized tokenized IMAPResponse
*/
-(void) setParsedBody:(id)tokenized {
    NSString* partIdentity = tokenized[0];
    NSString* partData = tokenized[1];
    
    NSSet* allParts = self.allParts;
    
//    [self willChangeValueForKey:@"defaultContent"];
    
    for (MBMime* mimePart in allParts) {
        if (mimePart.bodyIndex && [mimePart.bodyIndex caseInsensitiveCompare: partIdentity] == NSOrderedSame) {
            // found the correct part
            [mimePart addEncodedData: partData];
            BOOL isDecoded = [mimePart decode];
            BOOL isTEXT = [mimePart.type caseInsensitiveCompare: @"TEXT"] == NSOrderedSame;
            BOOL isPLAIN = [mimePart.subtype caseInsensitiveCompare: @"PLAIN"] == NSOrderedSame;
            NSInteger index = [mimePart.bodyIndex integerValue];
            if (isDecoded && isTEXT && (index == 1 || index == 0 || index == 1.1) ) {
                //
                NSString* compressed = [[[mimePart asAttributedStringWithOptions: nil attributes: nil] string] mdcCompressWitespace];
                NSUInteger summaryLength = MIN(compressed.length, 200);
                NSString* summary = [compressed substringToIndex: summaryLength];
                
                if (isPLAIN || ![self.summary isNonNilString]) {
                    // some bodies will not have a PLAIN option so we set the summary anyhow.
                    // if PLAIN is found, it may overwrite the non-PLAIN summary.
                    // PLAIN is chosen for the summary as it is hoped it would be the best summary representation.
                    self.summary = summary;
                }
            }
//            if ([mimePart isKindOfClass:[MBMimeText class]]) {
//                [self setDefaultContent: mimePart.data.encoded];
//            }
            
            break;
        }
    }
    
//    [self didChangeValueForKey:@"defaultContent"];
}
/*!
 The fields of the envelope structure are in the following
 order: date, subject, from, sender, reply-to, to, cc, bcc,
 in-reply-to, and message-id.  The date, subject, in-reply-to,
 and message-id fields are strings.  The from, sender, reply-to,
 to, cc, and bcc fields are parenthesized lists of address
 structures.
 
 Envelope   = "(" env-date SP env-subject SP env-from SP
 env-sender SP env-reply-to SP env-to SP env-cc SP
 env-bcc SP env-in-reply-to SP env-message-id ")"
 
 
 An address structure is a parenthesized list that describes an
 electronic mail address.  The fields of an address structure
 are in the following order: personal name, [SMTP]
 at-domain-list (source route), mailbox name, and host name.
 [RFC-2822] group syntax is indicated by a special form of
 address structure in which the host name field is NIL.  If the
 mailbox name field is also NIL, this is an end of group marker
 (semi-colon in RFC 822 syntax).  If the mailbox name field is
 non-NIL, this is a start of group marker, and the mailbox name
 field holds the group name phrase.
 
 env-bcc         = "(" 1*address ")" / nil
 
 env-cc          = "(" 1*address ")" / nil
 
 env-date        = nstring
 
 env-from        = "(" 1*address ")" / nil
 
 env-in-reply-to = nstring
 
 env-message-id  = nstring
 
 env-reply-to    = "(" 1*address ")" / nil
 
 env-sender      = "(" 1*address ")" / nil
 
 env-subject     = nstring
 
 env-to          = "(" 1*address ")" / nil
 
 */
-(void) setParsedEnvelope:(id)tokenized {
    MBTokenTree* tokenScanner = nil;
    if ([tokenized isKindOfClass: [MBTokenTree class]]) {
        tokenScanner = (MBTokenTree*) tokenized;
    } else if ([tokenized isKindOfClass: [NSArray class]]) {
        tokenScanner = [[MBTokenTree alloc] initWithArray: tokenized];
    } else {
        DDLogError(@"%@ the token list was: %@ which is neither an Array or TokenTree", NSStringFromSelector(_cmd), NSStringFromClass([tokenized class]));
    }
    
    //env-date string
    NSString* dateToken = [tokenScanner scanString];
    if ([dateToken isNonNilString]) {
        [self setParsedDateSent: dateToken];
    } else {
        [tokenScanner removeToken];
    }
    
    //env-subject string
    NSString* subjectToken = [tokenScanner scanString];
    if ([subjectToken isNonNilString]) {
        [self setParsedSubject: subjectToken];
    } else {
        [tokenScanner removeToken];
    }
    
    MBTokenTree* addressTokens;
    
    //env-from array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressFrom: addressTokens];
    
    //env-sender array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressSender: addressTokens];
    
    //env-reply-to array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressReplyTo: addressTokens];
    
    //env-to array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressesTo: addressTokens];
    
    //env-cc array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressesCc: addressTokens];
    
    //env-bcc array
    addressTokens = [tokenScanner scanSubTree];
    [self setParsedAddressesBcc: addressTokens];
    
    //env-in-reply-to array
    addressTokens = [tokenScanner scanSubTree];
    // throw away for now
    
    //env-message-id string
    NSString* messageIDToken = [tokenScanner scanString];
    if ([messageIDToken isNonNilString]) {
        [self setParsedMessageId: messageIDToken];
    }
    
    
}
/*
 <__NSArrayM 0x1003574d0>(
 <__NSArrayM 0x100357d60>(
 Randy and Diane Kane,
 NIL,
 mabbymia,
 comcast.net
 )
 
 )
*/

-(NSString*) composeContent {
    
    return nil;
}

/*!
 Need to make this KVO so views update.
 Need to setup compound property observer?
 */
//-(NSString*) defaultContent {
//    
//    NSOrderedSet* rootNodes = self.childNodes;
//    MBMime* firstMime = [rootNodes objectAtIndex: 0];
//    
//    NSString* result = nil;
//    
//    for (MBMime* mimePart in self.allParts) { 
//        if ([mimePart isKindOfClass:[MBMimeText class]]) {
//            result = mimePart.data.encoded;
//        }
//    }
//    
//    return result;
//}

//-(NSArray*) childNodesArray {
//    return [self.childNodes array];
//}
//-(NSSet*) childNodesSet {
//    return [self.childNodes set];
//}

/*!
<pre>
 RFC 2045 - Internet Message Bodies
 
 Bodystructure:
 Part()
 
 MultiPart( 
     Part() 
     Part() 
     subtype 
     Parameters("name" "value") 
     disposition 
     language 
     location)

 Message( 
 Part() 
 Part() 
 subtype 
 Parameters("name" "value") 
 disposition 
 language 
 location)

 Part:
 ("type" 
     "subtype" 
     Parameters("name" "value") 
     ContentID 
     Description 
     Encoding  
     Octets 
     Lines 
     MD5 
     disposition(type Parameters("name" "value")) 
     Language 
     Location)
 
 
 Default empty =  ("TEXT" "PLAIN" ("CHARSET" "US-ASCII") NIL NIL "7BIT" 0 0 NIL NIL NIL NIL)
 
 ("TEXT" "PLAIN" ("CHARSET" "US-ASCII") NIL NIL "7BIT" 2279 48)
 
 (
 ("TEXT" "PLAIN" ("CHARSET" "US-ASCII") NIL NIL "7BIT" 1152 23)
 ("TEXT" "PLAIN" ("CHARSET" "US-ASCII" "NAME" "cc.diff") "<960723163407.20117h@cac.washington.edu>" "Compiler diff" "BASE64" 4554 73)
 "MIXED"
 )
 
 (
 ("text" "plain" ("charset" "us-ascii") NIL NIL "quoted-printable" 228 15 NIL NIL NIL NIL)
 ("text" "html" ("charset" "us-ascii") NIL NIL "quoted-printable" 501 35 NIL NIL NIL NIL)
 "alternative" 
 ("boundary" "--------MB_8CE1CEFFDBAC413_2628_6BB_web-mmc-m09.sysops.aol.com") NIL NIL NIL)
 )
</pre>
 
 Multipart or non-multipart?
 Next token after bodystructure should be an array.
 If the first token in the array is another array,
 then it is multi-part, set message multi-part? and we need to recurse until the first token is a value
 then send the containing array to be parsed and unwind.
 
 **If messagePart.childParts is non-NIL and count>0 then it is multiPart. Should have no data.
 ** Frequently top level messagePart may only have a subtype and childParts.
 
 Note multiPart has no bodyIndex.
 
 message has one part - message.parts which is either a part or multiPart
 if part, then content and data is in the part, done.
 else multiPart, then subtype is? and content is in the childParts. (A childPart can be a multiPart)
 
 @param tokenized tokenized IMAPResponse
 */
-(void) setParsedBodystructure:(id)tokenized {
    MBMime* newPart = nil;
    MBTokenTree* tokenScanner = nil;
    if ([tokenized isKindOfClass: [MBTokenTree class]]) {
        tokenScanner = (MBTokenTree*) tokenized;
    } else if ([tokenized isKindOfClass: [NSArray class]]) {
        tokenScanner = [[MBTokenTree alloc] initWithArray: tokenized];
    } else {
        DDLogError(@"%@ the token list was: %@ which is neither an Array or TokenTree", NSStringFromSelector(_cmd), NSStringFromClass([tokenized class]));
    }
    
    newPart = [self unpackCompositeMimeFrom: tokenScanner];

    NSMutableOrderedSet* childNodes = [self mutableOrderedSetValueForKey: @"childNodes"];
    NSMutableSet* allParts = [self mutableSetValueForKey: @"allParts"];
    
    if (newPart) {
        if (newPart.childNodes.count == 0) {
            // discrete mime, bodyIndex = 1
            newPart.bodyIndex = @"1";
        } else {
            // multipart
            newPart.bodyIndex = @"";
            [self generateBodyIndexes: newPart path: nil rIndex: 0];
        }
//        newPart.bodyIndex = [NSString stringWithFormat: @"%u", partIndex];
        BOOL alreadyExists = NO;
        for (MBMime* existingPart in allParts) {
            if ([existingPart.bodyIndex isEqualToString: newPart.bodyIndex]) {
//                alreadyExists = YES;
            }
        }
        if (!alreadyExists) {
            [childNodes addObject: newPart];
            [allParts addObject: newPart];
        }
    } else {
        DDLogVerbose(@"%@ problem creating a new mime part.", NSStringFromSelector(_cmd));                
    }
}

/*
 @discussion From RFC3501
 
"Every message has at least one part number. Non-[MIME-IMB] messages,
 and non-multipart [MIME-IMB] messages with no encapsulated message, 
 only have a part 1. 
 
 Multipart messages are assigned consecutive part numbers, as they occur 
 in the message. If a particular part is of type message or multipart, 
 its parts MUST be indicated by a period followed by the part number 
 within that nested multipart part."
 
 This means the multiPart part should have no index since it has no individual content.
 The initial multiPart has no index and the parts are 1, 2
 An sub mulitpart has no index and the parts are 1.1, 1.2 or similar.
 
 Only multiParts have childnodes?
 
<pre>
 Body index
 n = Count contents of top level, index 1-n
 x = count of contents of 1-n, ".1-.x" for each n
 
 top level has nil for parentNode
 
 if parentNode == nil
    index = empty string
 Else
    if childNodes != nil
        for each node
            if prefix != "" prefix += "."
            bodyIndex = prefix+index
            if node.childNodes != nil
                recurse
</pre>
 
*/
- (void) generateBodyIndexes: (MBMime*) mime path: (NSArray*) path rIndex: (NSUInteger) rIndex{
    if (rIndex < 20) {
        // plan to pass copy of path array for each path recursion adding to the array with the next part index.
        // when at a leaf, set bodyindex using [path componentsJoinedByString: @"."]
        // index only gets added when there is a branch, meaning only add branch index.
        
        if (mime.childNodes.count == 0) {
            // leaf, set bodyindex
            mime.bodyIndex = [path componentsJoinedByString: @"."];
        } else if (mime.childNodes.count > 1){
            if (!path) {
                path = [NSMutableArray arrayWithCapacity: 2];
            }
            NSUInteger partIndex = 1;
            for (MBMime* node in mime.childNodes) {
                // branches
                NSString* nextIndexString = [NSString stringWithFormat:@"%lu",(unsigned long)partIndex];
                NSArray* nextPath = [path arrayByAddingObject: nextIndexString];
                [self generateBodyIndexes: node path: nextPath rIndex: rIndex];
                
                partIndex++;
            }
        } else if (mime.childNodes.count == 1) {
            // special case of message/rfc822 ?
            MBMime* node = [mime.childNodes objectAtIndex: 0];
            [self generateBodyIndexes: node path: path rIndex: rIndex];
        }
        
//        NSString* prefix = nil;
//        if (rIndex > 0) {
//            prefix = [NSString stringWithFormat: @"%lu.",rIndex];
//        } else {
//            prefix = @"";
//        }
//        NSUInteger index = 1;
//        for (MBMime* node in mime.childNodes) {
//            //
//            if ([node.type caseInsensitiveCompare: @"MULTIPART"] != NSOrderedSame) {
//                // not multipart, multipart does not get index
//                node.bodyIndex = [NSString stringWithFormat: @"%@%lu",prefix,(unsigned long)index];
//            }
//            DDLogVerbose(@"%@\n", node);
//            if ([node.childNodes count]>0) {
//                [self generateBodyIndexes: node path: path rIndex: ++rIndex];
//            }
//            index++;
//        }

    } else {
        DDLogError(@"%@ Maximum recursion exceeded.", NSStringFromSelector(_cmd));
    }
}

/*!
<pre>
 MultiPart( Part() Part() subtype Parameters("name" "value") disposition language location)

    leaf = ( ..... )
 
    node = ( (...) (...) ((....) (....) "alternate" ...) "mixed" ...)
 
 Distinguished by whether first element is non-array.
 
 above structure is transformed to: 
 
     anArray
        anArray - values
        anArray
            anArray - values
            anArray - values
            value
            value
        value
        value
 

 
     Is firstToken an array?
         yes - multipart
            do until firstToken not an array
                recurse
                add returned value as childNode
            add subtype
            add parameters
            add disposition
            add language
            add location
         no - leaf
            create leaf 
            remove token
            return leaf
</pre>
 
 ### Two types of multipart
 
 1. multipart -- data consisting of multiple entities of independent data types.  Four subtypes are initially defined, including the basic 
 "mixed" subtype specifying a generic mixed set of parts, 
 "alternative" for representing the same data in multiple formats,
 "parallel" for parts intended to be viewed simultaneously, and 
 "digest" for multipart entities in which each part has a default type of "message/rfc822"
 
 2. message -- an encapsulated message.  A body of media type 
 "message" is itself all or a portion of some kind of message object.  Such objects may or may not in turn contain other entities.  
 The "rfc822" subtype is used when the encapsulated content is itself an RFC 822 message.  
 The "partial" subtype is defined for partial RFC 822 messages, to permit the fragmented transmission of bodies that are thought to be too large to be passed through transport facilities in one piece.  
 Another subtype, "external-body", is defined for specifying large bodies by reference to an external data source.
 
 MultiPart is implied while Message is explicit.
 
 * If first token is an array, then it is Composite Multipart
 
 * If first token is "message", then it is Composite Message
 
 All else is discrete mime type.

 @param parts MBTokenTree
*/
#pragma message "ToDo: add special case of \"message\" which has a structure similar to a leaf with message as the first token."
-(MBMime*) unpackCompositeMimeFrom: (MBTokenTree*) parts {
    MBMime* result = nil;
    
    MBTokenTree* firstToken = [parts scanSubTree];
    
    if (firstToken!=nil) {
        // if there is a subTree, then this mime is multipart

        NSMutableOrderedSet* mimeParts = [[NSMutableOrderedSet alloc] initWithCapacity: 2];
        
        NSUInteger partIndex = 1;
        
        while (firstToken!=nil) {
            MBMime* subPart = [self unpackCompositeMimeFrom: firstToken];
            if (subPart) {
                [mimeParts addObject: subPart];
                subPart.subPartNumber = @(partIndex);
                [self addAllPartsObject: subPart];
            }
            // get the next subPart if there is one
            firstToken = [parts scanSubTree];
            partIndex++;
        }
        NSString* subtype = [parts scanString];
        if (subtype!=nil) {
            if ([subtype caseInsensitiveCompare: @"alternative"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiAlternative"
                          inManagedObjectContext: self.managedObjectContext];
            } else if ([subtype caseInsensitiveCompare: @"digest"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiDigest"
                          inManagedObjectContext: self.managedObjectContext];

            } else if ([subtype caseInsensitiveCompare: @"encrypted"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiEncrypted"
                          inManagedObjectContext: self.managedObjectContext];

            } else if ([subtype caseInsensitiveCompare: @"mixed"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiMixed"
                          inManagedObjectContext: self.managedObjectContext];
                
            } else if ([subtype caseInsensitiveCompare: @"parallel"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiParallel"
                          inManagedObjectContext: self.managedObjectContext];

            } else if ([subtype caseInsensitiveCompare: @"related"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiRelated"
                          inManagedObjectContext: self.managedObjectContext];

            } else if ([subtype caseInsensitiveCompare: @"signed"] == NSOrderedSame) {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMultiSigned"
                          inManagedObjectContext: self.managedObjectContext];

            } else {
                result = [NSEntityDescription
                          insertNewObjectForEntityForName: @"MBMimeMulti"
                          inManagedObjectContext: self.managedObjectContext];

            }
            result.subtype = subtype;
            result.type = @"Multipart";
            [result addChildNodes: mimeParts];
            [self addAllPartsObject: result];
        }
        // parameters
        MBTokenTree* parameterTokens = [parts scanSubTree];
        if (parameterTokens!=nil) {
            NSSet* parameters = [self unpackParametersOfClass: [MBMimeParameter class] fromNextToken: parameterTokens];
            if (parameters) {
                result.parameters = parameters;
                for (MBMimeParameter* parameter in parameters) {
                    if ([parameter.name caseInsensitiveCompare: @"boundary"]==NSOrderedSame) {
                        [(MBMimeMulti*)result setBoundary: parameter.value];
                    }
                }
            }

        } else {
            [parts removeToken];
        }
        // Disposition
        MBTokenTree* dispositionTokens = [parts scanSubTree];
        if (dispositionTokens!=nil) {
            MBMimeDisposition* disposition = [self unpackDispositionFromNextToken: dispositionTokens];
            if (disposition!=nil) result.disposition = disposition;
        } else {
            [parts removeToken];
        }
        // location
        NSString* language = [parts scanString];
        if (language!=nil) result.language = language;
        
        // location
        NSString* location = [parts scanString];
        if (location!=nil) result.location = location;
        
    } else if ([[parts peekToken] caseInsensitiveCompare: @"message"]==NSOrderedSame) {
        // it is a Composite Message mime
        result = [self unpackSubMessageMimeFrom: parts];
    } else {
        // it is a discrete mime or empty
        result = [self unpackDiscreteMimeFrom: parts];
    }
    return result;
}

/*!
 A body type of type MESSAGE and subtype RFC822 contains,
 immediately after the basic fields, the envelope structure,
 body structure, and size in text lines of the encapsulated
 message.
 
 > Explicit Composite Message
     type = message
     subtype = rfc822
     parameters
     contentID
     description
     encoding
     octets
     Envelope
     bodystructure
     lines
     md5
     disposition
     language
     location
 
 
 
 @param tokens MBTokenTree
 */
- (MBMime*) unpackSubMessageMimeFrom:(MBTokenTree *)tokens {
    
    MBMimeMessage* newPart = nil;
    MBMessage* subMessage = nil;
    
    NSString* type = [tokens scanString];
    if (type!=nil) {
        if ([type caseInsensitiveCompare: @"message"] == NSOrderedSame) {
            newPart = [MBMimeMessage insertNewObjectIntoContext: self.managedObjectContext];
        }
        newPart.type = type;
    }
    // subtype
    NSString* subtype = [tokens scanString];
    if (subtype!=nil) {
        newPart.subtype = subtype;
        if ([subtype caseInsensitiveCompare: @"rfc822"] == NSOrderedSame) {
            subMessage = [MBMessage insertNewObjectIntoContext: self.managedObjectContext];
            newPart.subMessage = subMessage;
        }
    }
    
    // parameters
    MBTokenTree* parameterTokens = [tokens scanSubTree];
    if (parameterTokens!=nil) {
        NSSet* parameters = [self unpackParametersOfClass: [MBMimeParameter class] fromNextToken: parameterTokens];
        if (parameters!=nil) {
            newPart.parameters = parameters;
            for (MBMimeParameter* parameter in parameters) {
                if ([parameter.name caseInsensitiveCompare: @"charset"] == NSOrderedSame) {
                    newPart.charset = [parameter.value lowercaseString];
                }
            }
        }
        
    } else {
        [tokens removeToken];
    }
    
    // ContentID
    NSString* contentid = [tokens scanString];
    if (contentid!=nil) newPart.id = contentid;
    
    // Description
    NSString* description = [tokens scanString];
    if (description!=nil) newPart.desc = description;
    
    // Encoding
    NSString* encoding = [tokens scanString];
    if (encoding!=nil) newPart.encoding = encoding;
    
    // Octets
    NSNumber* octets = [tokens scanNumber];
    if (octets!=nil) newPart.octets = octets;
    
    // Envelope
    MBTokenTree* subMessageEnvelope = [tokens scanSubTree];
    if (subMessageEnvelope!=nil) {
        [subMessage setParsedEnvelope: subMessageEnvelope];
    } else {
        [tokens removeToken];
    }
    
    // subMessage Bodystructure
    MBTokenTree* subBodystructure = [tokens scanSubTree];
    if (subBodystructure!=nil) {
        // recurse to unpack
        [subMessage setParsedBodystructure: subBodystructure];
        if (subMessage.childNodes.count > 0) {
            NSMutableOrderedSet* childNodes = [newPart mutableOrderedSetValueForKey: @"childNodes"];
            for (MBMime* part in subMessage.childNodes) {
                [childNodes addObject: part];
            }
            [self addAllParts: subMessage.allParts];
        }
//        MBMime* newChild = [self unpackCompositeMimeFrom: subBodystructure];
//        if (newChild != nil) {
//            NSMutableOrderedSet* childNodes = [newPart mutableOrderedSetValueForKey: @"childNodes"];
//            [childNodes addObject: newChild];
//        }
    } else {
        [tokens removeToken];
    }
    
    // Lines
    NSNumber* lines = [tokens scanNumber];
    if (lines!=nil) newPart.lines = lines;
    
    // Md5
    NSString* md5 = [tokens scanString];
    if (md5!=nil) newPart.md5 = md5;
    
    // disposition
    MBTokenTree* dispositionTokens = [tokens scanSubTree];
    if (dispositionTokens!=nil) {
        MBMimeDisposition* disposition = [self unpackDispositionFromNextToken: dispositionTokens];
        if (disposition!=nil) {
            newPart.disposition = disposition;
            if ([disposition.type caseInsensitiveCompare: @"inline"] == NSOrderedSame) {
                newPart.isInline = @YES;
            } else if ([disposition.type caseInsensitiveCompare: @"attachment"] == NSOrderedSame) {
                newPart.isAttachment = @YES;
            }
        }
    } else {
        [tokens removeToken];
    }
    // Language
    NSString* language = [tokens scanString];
    if (language!=nil) newPart.language = language;
    
    // Location
    NSString* location = [tokens scanString];
    if (location!=nil) newPart.location = location;
    
    [tokens removeAllObjects];
    return newPart;
}

/*!
 ("type" "subtype" Parameters("name" "value") ContentID Description Encoding  Octets Lines MD5 disposition(type Parameters("name" "value")) Language Location)
 
 @param tokens MBTokenTree
*/
-(MBMime*) unpackDiscreteMimeFrom: (MBTokenTree*) tokens {
    
    MBMime* newPart = nil;
     
    // type
    NSString* type = [tokens scanString];
    if (type!=nil) {
        if ([type caseInsensitiveCompare: @"text"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeText"
                      inManagedObjectContext: self.managedObjectContext];
        } else if ([type caseInsensitiveCompare: @"application"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeApplication"
                      inManagedObjectContext: self.managedObjectContext];
            
        } else if ([type caseInsensitiveCompare: @"image"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeImage"
                      inManagedObjectContext: self.managedObjectContext];
            
        } else if ([type caseInsensitiveCompare: @"audio"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeAudio"
                      inManagedObjectContext: self.managedObjectContext];
            
        } else if ([type caseInsensitiveCompare: @"video"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeVideo"
                      inManagedObjectContext: self.managedObjectContext];
            
        } else if ([type caseInsensitiveCompare: @"micalg"] == NSOrderedSame) {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeText"
                      inManagedObjectContext: self.managedObjectContext];
            
        } else {
            newPart = [NSEntityDescription
                      insertNewObjectForEntityForName: @"MBMimeText"
                      inManagedObjectContext: self.managedObjectContext];
            
        }
        newPart.type = type;
        newPart.isLeaf = @YES;
    }
    // Need to dispatch based on type "partTypeMessage:" "partTypeText:",....
    
    
    // subtype
    NSString* subtype = [tokens scanString];
    if (subtype!=nil) newPart.subtype = subtype;

    // parameters
    MBTokenTree* parameterTokens = [tokens scanSubTree];
    if (parameterTokens!=nil) {
        NSSet* parameters = [self unpackParametersOfClass: [MBMimeParameter class] fromNextToken: parameterTokens];
        if (parameters!=nil) {
            newPart.parameters = parameters;
            for (MBMimeParameter* parameter in parameters) {
                if ([parameter.name caseInsensitiveCompare: @"charset"] == NSOrderedSame) {
                    newPart.charset = [parameter.value lowercaseString];
                } else
                if ([parameter.name caseInsensitiveCompare: @"name"] == NSOrderedSame) {
                    newPart.name = [parameter.value lowercaseString];
                }
            }
        }

    } else {
        [tokens removeToken];
    }
    // ContentID
    NSString* contentid = [tokens scanString];
    if (contentid!=nil) newPart.id = contentid;

    // Description
    NSString* description = [tokens scanString];
    if (description!=nil) newPart.desc = description;

    // Encoding
    NSString* encoding = [tokens scanString];
    if (encoding!=nil) newPart.encoding = encoding;

    // Octets
    NSNumber* octets = [tokens scanNumber];
    if (octets!=nil) newPart.octets = octets;

    // Lines
    NSNumber* lines = [tokens scanNumber];
    if (lines!=nil) newPart.lines = lines;

    // Md5
    NSString* md5 = [tokens scanString];
    if (md5!=nil) newPart.md5 = md5;

    // disposition
    MBTokenTree* dispositionTokens = [tokens scanSubTree];
    if (dispositionTokens!=nil) {
        MBMimeDisposition* disposition = [self unpackDispositionFromNextToken: dispositionTokens];
        if (disposition!=nil) {
//            newPart.disposition = disposition;
            [disposition setMime: newPart];
            if ([disposition.type caseInsensitiveCompare: @"inline"] == NSOrderedSame) {
                newPart.isInline = @YES;
            } else 
            if ([disposition.type caseInsensitiveCompare: @"attachment"] == NSOrderedSame) {
                newPart.isAttachment = @YES;
                self.hasAttachment = @YES;
            }
            if (disposition.parameters != nil) {
                for (MBMimeParameter* parameter in disposition.parameters) {
                    if ([parameter.name caseInsensitiveCompare: @"filename"] == NSOrderedSame) {
                        [newPart setFilename: [parameter.value lowercaseString]];
                    } 

                }

            }
        }
    } else {
        [tokens removeToken];
    }
    // Language
    NSString* language = [tokens scanString];
    if (language!=nil) newPart.language = language;

    // Location
    NSString* location = [tokens scanString];
    if (location!=nil) newPart.location = location;
    
    [tokens removeAllObjects];
    return newPart;
}


/*!
 disposition(type Parameters("name" "value"))
 
 @param dispositionTokens MBTokenTree
 */
-(MBMimeDisposition*) unpackDispositionFromNextToken:(MBTokenTree *)dispositionTokens {
    MBMimeDisposition* newDisposition = nil;
    
    // dispositionTokens = (type parameters(...)) or NIL
    // we have disposition
    
    NSString* dtype = [dispositionTokens scanString];
    
    if (dtype!=nil) {
        // only create the newDisposition if we have a type
        newDisposition = [NSEntityDescription
                          insertNewObjectForEntityForName:@"MBMimeDisposition"
                          inManagedObjectContext: self.managedObjectContext];
        
        newDisposition.type = dtype;
        
    } else {
        [dispositionTokens removeAllObjects];
    }
    // dispositionTokens = ( parameters(...) )
    MBTokenTree* parameterTokens = [dispositionTokens scanSubTree];
    if (parameterTokens!=nil) {
        NSSet* dParameters = [self unpackParametersOfClass: [MBDispositionParameter class] fromNextToken: parameterTokens];
        if (dParameters!=nil) newDisposition.parameters = dParameters;
    } 
    
    [dispositionTokens removeAllObjects];
    
    return newDisposition;
}

-(NSSet*) unpackParametersOfClass:(Class)aClass fromNextToken:(MBTokenTree *)parameterTokens {
    NSMutableSet* parameters = [[NSMutableSet alloc] initWithCapacity: 2];
    
    // add key and value to dictionary
    NSString* nextToken = nil;
    nextToken=[parameterTokens scanString];
    while (nextToken!=nil) {
        id newParameter = [aClass insertNewObjectIntoContext: self.managedObjectContext];
        
        [newParameter setValue: [nextToken mdcStringAsSelectorSafeCamelCase] forKey: @"name"];
        [newParameter setValue: [parameterTokens scanString] forKey: @"value"];

        [parameters addObject: newParameter];
        nextToken = [parameterTokens scanString];
    }
    if (![parameterTokens isEmpty]) {
        // is there a leftover key missing a value?
        DDLogWarn(@"%@ - missing value argument. Throwing away: \n %@", NSStringFromSelector(_cmd), nextToken);
    }        
    
    [parameterTokens removeAllObjects];
    return parameters;
}

-(MBAddress*) checkAddress: (id) tokenized {
    MBAddress* address = nil;
    
    if ([tokenized isKindOfClass: [NSString class]] || [tokenized isKindOfClass: [SimpleRFC822Address class]]) {
        SimpleRFC822Address* rfcAddress = nil;
        
        if ([tokenized isKindOfClass: [NSString class]]) {
            
            rfcAddress = [SimpleRFC822Address newFromString: tokenized];//[tokenized mdcSimpleRFC822Address];
        } else {
            rfcAddress = tokenized;
        }
        
        address = [MBAddress newAddressWithEmail: rfcAddress.email createIfMissing: YES context: self.managedObjectContext];
        if (address) {
            address.name = rfcAddress.name;
            address.email = rfcAddress.email;
        }
        
    } else if ([tokenized isKindOfClass: [MBAddress class]]) {
        address = tokenized;
    }
    return address;
}


- (NSArray*) attachments {
    NSMutableArray* result = nil;

    for (MBMime* mimePart in self.allParts) {
        if (mimePart.isAttachment) {
            if (result == nil) {
                result = [[NSMutableArray alloc] initWithCapacity: 2];
            }
            [result addObject: mimePart];
        }
    }
    
    return result;
}
-(NSString*) checkAnd2047DecodeToken:(id)token {
    NSString* decodedString;
    if (token != nil && [token isKindOfClass: [NSString class]]) {
        decodedString = [token mdcStringByDecodingRFC2047];
    }
    return decodedString;
}
-(NSDate*) checkAndDecodeTokenAsDate:(id)token {
    NSDate* decodedDate;

    if (token != nil && [token isKindOfClass: [NSString class]]) {
        NSString* dateString = token;
        
        decodedDate = [NSDate newDateFromRFC3501FormatString: dateString];//[dateString mdcDateFromRFC3501Format];
        if (!decodedDate) {
            decodedDate = [NSDate newDateFromRFC822FormatString: dateString];//[dateString mdcDateFromRFC822Format];
        }
        
    } else if ([token isKindOfClass: [NSDate class]]) {
        decodedDate = token;
    }

    return decodedDate;
}
//-(id)copyWithZone:(NSZone *)zone { // shallow copy
//    // Want to pass a Dictionary to an NSFormatter rather than a copy of a value.
//    
//    MBAddress *temp = [self addressFrom];
//    NSString *fromName = temp.name;
//    NSString *fromEmail = temp.email;
//    if(temp == nil){
//        fromName = @"Unknown sender";
//        fromEmail = @"Unknown email";
//    }
//    
//    #pragma message "TODO: remove Temp stuff"
//    NSString *sampleBody = @"Just testing a long line of sample text to be replaced when IMAPClient is working.";
//    //sampleBody = self.body;
//    
//    NSDictionary *clone = [NSDictionary dictionaryWithObjectsAndKeys:
//                           fromName, @"addressFromName",
//                           fromEmail, @"addressFromEmail", 
//                           self.uid, @"uid", 
//                           self.dateSent, @"dateSent", 
//                           self.subject, @"subject", 
//                           sampleBody, @"body",
//                           nil];
//    return clone; 
//    return self;
//}

@end
