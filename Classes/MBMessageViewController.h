//
//  MBMessageViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MBMessage;

@interface MBMessageViewController : NSViewController

@property (strong, nonatomic) IBOutlet NSObjectController *messageController;
@property (strong, nonatomic)          MBMessage*         message;

@end
