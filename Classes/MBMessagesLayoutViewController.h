//
//  MBMessagesLayoutViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBMessage.h"

/*!
 Controls the layout of the MBMessagesLayoutViews
 
 Root view is an MBMessagesLayoutView
 
 Should implement a MBMessageDelegate protocol?
 */

@interface MBMessagesLayoutViewController : NSViewController

/*!
 messages are stored in the order of presentation?
 Perhaps should be an NSOrderedSet with sorting?
 Need to be able to change layouts:
    
 */

-(void) contain: (MBMessage*) currentMessage;

-(void) contains: (NSArray*) currentMessages;

@end
