//
//  MBGUIStateAutoSave.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBGUIStateAutoSave <NSObject>

/*!
 Saves the GUI state to a user preference entry.
 */
-(void) saveState;

@end
