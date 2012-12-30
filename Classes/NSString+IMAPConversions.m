//
//  NSString+IMAPConversions.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "NSString+IMAPConversions.h"
#import "SimpleRFC822Address.h"

#include <time.h>
#include <xlocale.h>

@implementation NSString (IMAPConversions)

/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 INTERNALDATE Format =  "26-Jul-2011 07:48:41 -0400"
 */
-(NSDate *) dateFromRFC3501Format {
    NSDate *            internalDate = nil;
    
    struct tm  sometime;
    const char *rfc3501DateFormat = "%e-%b-%Y %H:%M:%S %z";
    char* transformResult = strptime_l([self cStringUsingEncoding: NSUTF8StringEncoding], rfc3501DateFormat, &sometime, NULL);
    
    if (transformResult != NULL) {
        internalDate = [NSDate dateWithTimeIntervalSince1970: mktime(&sometime)];
    }
    return internalDate;
}
/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 "GMT"  obsolete
 */
-(NSDate *) dateFromRFC822Format {
    NSDate *internalDate = nil;
    static NSDateFormatter *sRFC2822DateFormatter = nil;
    //NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    
    static NSRegularExpression *sLocateRFC2822Date = nil;
    NSError *regexError;
    
    if (sRFC2822DateFormatter==nil) {
        sRFC2822DateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [sRFC2822DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC2822DateFormatter setDateFormat:@"dd MMM yyyy HH:mm:ss"];
        
        sLocateRFC2822Date = [[NSRegularExpression alloc] initWithPattern: @"(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s(.\\d{4})|(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s?\"?(\\w{3})"
                                                                  options: 0 
                                                                    error: &regexError];
    }
    if (self) {
        NSTextCheckingResult *dateFound = [sLocateRFC2822Date firstMatchInString: self 
                                                                         options: 0 
                                                                           range:NSMakeRange(0, [self length])];
        
        NSString *timeZoneString = nil;
        NSTimeZone *messageTimeZone = nil;
        NSRange dateRange;
        
        if ([dateFound numberOfRanges] >= 5) {
            // should be full plus two capture ranges
            // date should be @ 1
            // timezone should be at 2
            //DDLogVerbose(@"Ranges: %lu\n", [dateFound numberOfRanges]);
            //NSRange range0 = [dateFound rangeAtIndex: 0]; // full range of found expression
            NSRange range1 = [dateFound rangeAtIndex: 1];
            NSRange range2 = [dateFound rangeAtIndex: 2];
            NSRange range3 = [dateFound rangeAtIndex: 3];
            NSRange range4 = [dateFound rangeAtIndex: 4];
            
            if (range1.length >0 && range2.length > 0) {
                // first type
                timeZoneString = [self substringWithRange: range2];
                NSInteger timeZoneDecimal100Hours = [timeZoneString integerValue];
                messageTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: timeZoneDecimal100Hours*60*60/100];
                dateRange = range1;
                
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 1]]);
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 2]]);
            } else if (range3.length >0 && range4.length > 0) {
                // 2nd type
                timeZoneString = [self substringWithRange: range4];
                messageTimeZone = [NSTimeZone timeZoneWithAbbreviation: timeZoneString];
                if (messageTimeZone==nil) {
                    // default to GMT
                    messageTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
                }
                dateRange = range3;
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 3]]);
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 4]]);
            }
            
            [sRFC2822DateFormatter setTimeZone: messageTimeZone];
            
            [sRFC2822DateFormatter getObjectValue: &internalDate 
                                        forString: self 
                                            range: &dateRange  
                                            error: &regexError];
        }
        
    }
    
    return internalDate;
}

-(NSString *) stringAsSelectorSafeCamelCase {
    // commands like READ-ONLY become ReadOnly
    NSString *normalized = [self capitalizedString];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"-" withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"." withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"[" withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"]" withString: @""];
    return normalized;
}

-(SimpleRFC822Address*) rfc822Address {
    SimpleRFC822Address* rfcaddress = [[SimpleRFC822Address alloc] init];
    rfcaddress.name = self;
    rfcaddress.email = self;
    return rfcaddress;
}
@end
