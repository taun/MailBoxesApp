//
//  NSString+IMAPConversions.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimpleRFC822Address;

@interface NSString (IMAPConversions)

-(NSDate*) dateFromRFC3501Format;
-(NSDate*) dateFromRFC822Format;

-(NSString*) stringAsSelectorSafeCamelCase;

-(SimpleRFC822Address*) rfc822Address; 

@end
