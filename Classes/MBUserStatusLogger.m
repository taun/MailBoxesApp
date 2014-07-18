//
//  MBUserStatusLogger.m
//  MailBoxes
//
//  Created by Taun Chapman on 07/17/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBUserStatusLogger.h"

NSString *kMBStatusLoggerHasNewMessage = @"kMBStatusLoggerHasNewMessage";
NSString *kMBStatusLoggerMessageKey = @"kMBStatusLoggerMessageKey";
NSString *kMBStatusLoggerLogFlagKey = @"kMBStatusLoggerLogFlagKey";

@interface MBUserStatusLogger ()

@property (atomic,assign) NSUInteger            maxQueueLength;
@property (atomic,assign) NSUInteger            currentPosition;
@property (atomic,strong) NSMutableArray       *messageQueue;

-(void) addMessageToQueue: (NSString*) message;

@end

@implementation MBUserStatusLogger

- (id)init {
	if ((self = [super init]))	{
        _currentPosition = 10;
        _maxQueueLength = 10;
        _messageQueue = [NSMutableArray arrayWithCapacity: _maxQueueLength];
        for (int i=0; i < _maxQueueLength; i++) {
            [_messageQueue addObject: @""];
        }
	}
	return self;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *logMsg = logMessage->logMsg;
    
    if (self->formatter)
        logMsg = [self->formatter formatLogMessage:logMessage];
    
    if (logMsg) {
        [self addMessageToQueue: logMsg];
        NSNumber* logFlag = [NSNumber numberWithInt: logMessage->logFlag];
        NSDictionary* userInfo = @{kMBStatusLoggerMessageKey: self.currentMessage, kMBStatusLoggerLogFlagKey: logFlag};
        [[NSNotificationCenter defaultCenter] postNotificationName: kMBStatusLoggerHasNewMessage object: self userInfo: userInfo];
    }
}

-(void) addMessageToQueue:(NSString *)message {
    NSUInteger newPosition = (self.currentPosition == self.maxQueueLength) ? 0 : ++self.currentPosition;
    
    self.messageQueue[newPosition] = message;
    
    self.currentPosition = newPosition;
}

-(NSString*) currentMessage {
    return [self.messageQueue[self.currentPosition] copy];
}
@end
