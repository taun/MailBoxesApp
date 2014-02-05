//
//  MBMime+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/06/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime.h"
#import "MBMime+IntersectsSetFix.h"
#import "MBMimeData+IMAP.h"
#import "MBMIME2047ValueTransformer.h"
#import "MBMIMEQuotedPrintableTranformer.h"

#import <MoedaeMailPluginsBase/MMPMimeProxy.h>

extern NSString* MBRichMessageViewAttributeName;

/*!
 RFC 2045 - Internet Message Bodies
 
 Bodystructure:
 Part()
 MultiPart( Part() Part() subtype Parameters("name" "value") disposition language location)
 
 Part:
 ("type" "subtype" Parameters("name" "value") ContentID Description Encoding  Octets Lines MD5 disposition(type Parameters("name" "value")) Language Location)
 
 
 BODY {
 unsigned short type;		// body primary type 
 unsigned short encoding;	// body transfer encoding 
 char *subtype;              // subtype string 
 PARAMETER *parameter;		// parameter list 
 char *id;                   // body identifier 
 char *description;          // body description 
 struct {                    // body disposition 
 char *type;             // disposition type 
 PARAMETER *parameter;	// disposition parameters 
 } disposition;
 STRINGLIST *language;		// body language 
 char *location;             // body content URI 
 PARTTEXT mime;              // MIME header 
 PARTTEXT contents;          // body part contents 
 union {                     // different ways of accessing contents 
 PART *part;             // body part list 
 MESSAGE *msg;           // body encapsulated message 
 } nested;
 struct {
 unsigned long lines;	// size of text in lines 
 unsigned long bytes;	// size of text in octets 
 } size;
 char *md5;                  // MD5 checksum 
 void *sparep;               // spare pointer reserved for main program 
 };
 
 
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
 
 Multipart or non-multipart?
 Next token after bodystructure should be an array.
 If the first token in the array is another array,
 then it is multi-part, set message multi-part? and we need to recurse until the first token is a value
 then send the containing array to be parsed and unwind.
 
 **If messagePart.childParts is non-NIL and count>0 then it is multiPart. Should have no data.
 ** Frequently top level messagePart may only have a subtype and childParts.
 
 
 message has one part - message.parts which is either a part or multiPart
 if part, then content and data is in the part, done.
 else multiPart, then subtype is? and content is in the childParts. (A childPart can be a multiPart)
 
 
 */
@interface MBMime (IMAP)


- (void)encodeWithCoder:(NSCoder *)coder;

- (void) addEncodedData: (NSString*) encodedData;
/*!
 MIME Class specific method to decode MIME string data
 
 Needs to decode data.
 Set decoded property.
 Set isDecoded property.
 */
-(void) decoder;
/*!
 Decode mime decode data
 
 Converts encoded data to decoded data
 Erases encoded data
 sets isDecoded flag
  
 @result YES if successfully decoded.
 */
-(BOOL) decode;
/*!
 
 MBMimeData decoding is deferred until getDecodedData is called on MBMime. Calling MBMimeData.decoded
 will result in nil. This is to save the overhead of converting and storing conversions which may never be used.
 The downside is this may make search less useful and we may need to switch to decoding data during initial storage.
 
 Maybe a preference or variable to switch modes. Either way, getDecodedData will work the same.
 
 @result nil if there is no data or it cannot be decoded.
 */
-(NSData*) getDecodedData;

-(NSArray*) childNodesArray;
-(NSSet*) childNodesSet;

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes;

-(BOOL) hasRichMessageViewOption: (NSDictionary*) options;

-(MMPMimeProxy*) asMimeProxy;

@end
