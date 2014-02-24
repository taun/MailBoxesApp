//
//  NSObject+MBShorthand.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MBShorthand)
/**
 *  Utility to detect a non-nil, non-zero count array.
 *
 *  @return YES if the receiver isKindOfClass: NSArray and has a count > 0.
 */
-(BOOL) isNonZeroArray;
/**
 *  Utility method to detect whether the receiver is nil or an empty string.
 *
 *  @return YES if receiver is a non-nil, non-emtpy string.
 */
-(BOOL) isNonNilString;

@end
