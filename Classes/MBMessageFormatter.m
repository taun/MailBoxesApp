//
//  MBMessageFormatter.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/11/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessageFormatter.h"
#import "MBMessage+Accessors.h"

@implementation NSDate (whenString)

- (NSDate *)dateWithZeroTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *comps = [calendar components:unitFlags fromDate:self];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSString *)whenString
{
    NSDate *selfZero = [self dateWithZeroTime];
    NSDate *todayZero = [[NSDate date] dateWithZeroTime];
    NSTimeInterval interval = [todayZero timeIntervalSinceDate:selfZero];
    int dayDiff = interval/(60*60*24);
    
    // Initialize the formatter.
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if (dayDiff == 0) { // today: show time only
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    } else if (dayDiff == 1 || dayDiff == -1) {
        //return NSLocalizedString((dayDiff == 1 ? @”Yesterday” : @”Tomorrow”), nil);
        [formatter setDoesRelativeDateFormatting:YES];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
    } else if (dayDiff <= 7) { // < 1 week ago: show weekday
        [formatter setDateFormat:@"EEEE"];
    } else { // show date
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    return [formatter stringFromDate:self];
}

@end

@implementation MBMessageFormatter



- (NSString *)stringForObjectValue:(id)anObject {
    
    if (![anObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:usLocale];
    
    id fromName = [anObject valueForKey: @"addressFrom.name"];
    
    NSString *dateString = [NSString stringWithFormat:@"%@ %@ %@", 
                            fromName, 
                            [dateFormatter stringFromDate: [anObject valueForKey: @"dateSent"]] , 
                            [anObject valueForKey: @"subject"]];

    return dateString;
}

/*
 ToDo: add an icon to the front of the string for status.
 Read, unread, ...
 Add sender name to string.
 Means updating the MBMessageStatic clone to include those properties.
 NSAttributedString examples include an icon example.
 */
- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes {

//    if (![anObject isKindOfClass:[NSDictionary class]]) {
//        return nil;
//    }
    
    NSMutableDictionary *firstLineAttributes = [attributes mutableCopy];
    NSMutableParagraphStyle *firstParagraphStyle = [firstLineAttributes[NSParagraphStyleAttributeName] mutableCopy];
    
    // clear default tabs
    [firstParagraphStyle setTabStops:@[]];
    
    // add tab stop for right justifying the date
    [firstParagraphStyle addTabStop:[[NSTextTab alloc] initWithType: NSRightTabStopType location: 3.0*72.0]];
    
    [firstParagraphStyle setLineBreakMode: NSLineBreakByTruncatingMiddle];
    firstLineAttributes[NSParagraphStyleAttributeName] = firstParagraphStyle;
    
    // Want attributes to make from field bigger and bold.
    firstLineAttributes[NSFontAttributeName] = [NSFont fontWithName:@"LucidaGrande-Bold" size: 13.0];
    // NSForegroundColorAttributeName
    
    NSString *fromName = [anObject valueForKey: @"addressFrom.name"];
    NSString *from = ([fromName length] < 1) ? [anObject valueForKey: @"addressFrom.email"] : fromName;

    NSAttributedString *fromAttrString = [[NSAttributedString alloc] 
                                          initWithString: [NSString stringWithFormat: @"%@", from]
                                          attributes: firstLineAttributes];

    // want to make the date blue
    firstLineAttributes[NSFontAttributeName] = [NSFont fontWithName:@"LucidaGrande" size: 12.0];
    firstLineAttributes[NSForegroundColorAttributeName] = [NSColor blueColor];
    NSDate *date = [anObject  valueForKey: @"dateSent"];
    
    NSAttributedString *dateAttrString = [[NSAttributedString alloc] 
                                            initWithString: [NSString stringWithFormat:@" \t %@", [date whenString]]
                                            attributes: firstLineAttributes];
        
    
    NSMutableDictionary *secondLineAttributes = [attributes mutableCopy];
    NSMutableParagraphStyle *secondParagraphStyle = [secondLineAttributes[NSParagraphStyleAttributeName] mutableCopy];
    
    [secondParagraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
    secondLineAttributes[NSParagraphStyleAttributeName] = secondParagraphStyle;
    secondLineAttributes[NSFontAttributeName] = [NSFont fontWithName:@"LucidaGrande-Bold" size: 11.0];
    
    NSAttributedString *subjectAttrString = [[NSAttributedString alloc] 
                                             initWithString: [NSString stringWithFormat:@"\n%@", [anObject valueForKey: @"subject"]]
                                             attributes: secondLineAttributes];
    
    
    //[newAttributes setObject:[[NSFontManager sharedFontManager] convertFont: [NSFont fontWithName:@"LucidaGrande" size: 11.0] 
    //                                                         toHaveTrait: NSFontItalicTrait] forKey:NSFontAttributeName];
    
    //[paragraphStyle setLineBreakMode: NSLineBreakByWordWrapping];
    //[newAttributes setObject: paragraphStyle forKey: NSParagraphStyleAttributeName];

    NSMutableDictionary *bodyAttributes = [attributes mutableCopy];
    NSMutableParagraphStyle *bodyParagraphStyle = [bodyAttributes[NSParagraphStyleAttributeName] mutableCopy];
    
    [bodyParagraphStyle setLineBreakMode: NSLineBreakByWordWrapping];
    bodyAttributes[NSParagraphStyleAttributeName] = bodyParagraphStyle;
    bodyAttributes[NSFontAttributeName] = [NSFont fontWithName:@"LucidaGrande" size: 11.0];

    NSString *body = [anObject valueForKey: @"summary"];
    NSAttributedString *bodyAttrString = [[NSAttributedString alloc] 
                                             initWithString: [NSString stringWithFormat:@"\n%@", 
                                                              [body stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]]
                                             attributes: bodyAttributes];
    
    // [[anObject valueForKey: @"body"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]]

    // [[anObject valueForKey: @"body"] stringByReplacingOccurrencesOfString:@" +" withString:@" " options: NSRegularExpressionSearch range: NSMakeRange(0, 0)];
    
    
    NSMutableAttributedString *cellAttrString = [[NSMutableAttributedString alloc] 
                                                 initWithAttributedString: fromAttrString];
    
    [cellAttrString appendAttributedString: dateAttrString];
    [cellAttrString appendAttributedString: subjectAttrString];
    [cellAttrString appendAttributedString: bodyAttrString];
    
    
    
    return cellAttrString;    
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    return NO;
}

@end
