//
//  MBMimeView.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/29/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBMime+IMAP.h"

/*!
 Abstract Class for all Message Mime Content
 
 Also need a message body protocol.
 
 Would only be used for unkown mime type content and show raw content.
 */
@interface MBMimeView : NSView

@property (nonatomic,strong) MBMime         *node;
@property (nonatomic,strong) NSDictionary   *options;
@property (nonatomic,strong) NSDictionary   *attributes;

/* designated initializer */
-(instancetype) initWithFrame:(NSRect)frameRect node: (MBMime*)node;

/* abstract, probably should be made private */ 
-(void) createSubviews;

/* abstract needs to be implemented by subclass */
-(void) reloadData;

@end
