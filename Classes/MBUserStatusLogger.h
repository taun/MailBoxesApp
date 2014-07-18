//
//  MBUserStatusLogger.h
//  MailBoxes
//
//  Created by Taun Chapman on 07/17/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "DDLog.h"

extern NSString *kMBStatusLoggerHasNewMessage;
extern NSString *kMBStatusLoggerMessageKey;
extern NSString *kMBStatusLoggerLogFlagKey;

@interface MBUserStatusLogger : DDAbstractLogger <DDLogger>

@property (atomic,assign) BOOL                 newMessageAvailable;
@property (readonly,strong) NSString             *currentMessage;

@end
