//
//  MBMessagesSplitViewDelegate.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBGUIStateAutoSave.h"

extern NSString *const MBUPMessagesSplitIsVertical;


@interface MBMessagesSplitViewDelegate : NSObject <NSSplitViewDelegate, MBGUIStateAutoSave>

@property(strong)     IBOutlet  NSSplitView       *messagesSplitView;

-(IBAction) toggleMessagesVerticalView:(id)sender;


@end
