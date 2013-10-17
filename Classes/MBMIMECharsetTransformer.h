//
//  MBMIMECharsetTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma message "Need to write charset tests"

/*!
 Transforms from MIME strings representing a character set to an NSNumber representing an NS domain character set.
 
 Will handle upper or lower case MIME strings.
 
 @returns nil if charset is not found.
 */
@interface MBMIMECharsetTransformer : NSValueTransformer

@end
