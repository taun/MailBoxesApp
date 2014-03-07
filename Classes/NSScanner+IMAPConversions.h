//
//  NSScanner+IMAPConversions.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/07/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (IMAPConversions)

/*!
 This only gets called if there was an "=" found.
 Location is the first "X" after the "=".
 Current location of string should be of form ="XY".
 
 Result
 
 * if XY is valid hex, returns XY as UInt8 with location after "=XY"
 * If X is valid and Y is invalid, returns X as UInt8 and location at Y
 * If X and Y are invalid, return 0 and location still at X
 
 */
-(UInt8) mdcScanQHexUnichar;

@end
