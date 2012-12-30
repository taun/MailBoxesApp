//
//  RFC2822Message.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 An RFC2822 Object
 Set it's content which should be raw RFC2822 formatted text.
 Ask for various elements of content such as subject, from, to, ..
 
 
 
 
 use:
 
 Data is stored as elements not raw. That way raw can be composed and output,
 elements can be replaced.
 
 Only time complete rfc would be around is on creation or output view
 
 */
@interface RFC2822Message : NSObject

@end
