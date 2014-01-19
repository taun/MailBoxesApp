//
//  MBMimeView.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/29/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 Abstract Class for all Message Mime Content
 
 Also need a message body protocol.
 
 Would only be used for unkown mime type content and show raw content.
 */
@interface MBMimeView : NSView

@end
