//
//  NSScanner+IMAPConversions.m
//  MailBoxes
//
//  Created by Taun Chapman on 03/07/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "NSScanner+IMAPConversions.h"

@implementation NSScanner (IMAPConversions)


-(UInt8) mdcScanQHexUnichar {
    UInt8 hexCode = 0;
    
    if (isxdigit([self.string characterAtIndex: self.scanLocation])
        && isxdigit([self.string characterAtIndex: self.scanLocation+1])) {
        // have to hexadecimal digits
        UInt8 hex16ASCII = [self.string characterAtIndex: self.scanLocation];
        [self setScanLocation: ++(self.scanLocation)];
        UInt8 hex16 = isdigit(hex16ASCII) ? (hex16ASCII - '0') : (hex16ASCII - 55);
        if (hex16 > 15) hex16 -= 32;  // lowercase a-f
        
        UInt8 hex1ASCII = [self.string characterAtIndex: self.scanLocation];
        [self setScanLocation: ++(self.scanLocation)];
        UInt8 hex1 = isdigit(hex1ASCII) ? (hex1ASCII - '0') : (hex1ASCII - 55);
        if (hex1 > 15) hex1 -= 32;  // lowercase a-f
        
        hexCode = (hex16 << 4) + hex1;
    } else if (isxdigit([self.string characterAtIndex: self.scanLocation])
               && !isxdigit([self.string characterAtIndex: self.scanLocation+1])) {
        // only one valid hex digit
        UInt8 hex16ASCII = [self.string characterAtIndex: self.scanLocation];
        [self setScanLocation: ++(self.scanLocation)];
        UInt8 hex16 = isdigit(hex16ASCII) ? (hex16ASCII - '0') : (hex16ASCII - 55);
        if (hex16 > 15) hex16 -= 32;  // lowercase a-f
        
        hexCode = hex16;
    }
    
    return hexCode;
}

@end
