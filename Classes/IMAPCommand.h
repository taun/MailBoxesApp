//
//  IMAPCommand.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/19/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPResponse.h"

@class MBAccount;
@class MBox;

/*!
 @header
 
 more later

*/

/*!
 @class IMAPCommand
 
 
 @abstract more later
 
 @discussion Base class for commands. Should never be used.
 A subclass per command is required
 */
@interface IMAPCommand : NSObject

@property (copy)      NSString *           atom;
@property (copy)      NSString *           tag;
@property (copy)      NSString *           info;
@property (copy)      NSString *           mboxFullPath;
@property (strong)    MBox *               mbox;

@property (assign)      BOOL                isActive;
@property (assign)      BOOL                isDone;
@property (assign)      BOOL                hasLiteral;
@property (strong)      NSData *            literal;

@property (assign)      IMAPResponseStatus  responseStatus;

- (NSString*) debugDescription;

/*!
 @method initWithAtom: (NSString*) commandString;
 @discussion designated initializer
 @param commandString more later
 @result self
 */
-(id)initWithAtom: (NSString*) commandString;

/*!
 @method addArgument: (NSString*) argument;
 @discussion add an argument to command
 @param argument more later
 */
-(void)copyAddArgument: (NSString*) argument;


/*!
 @method nextOutput
 @discussion output the required formatted command string to be streamed to the server.
 If a server continuation is required before the next output,
 nextOutput will enumerate through the required outputs.
 If there is only one line of output will return the same line each call.

 @result a command string
 */
-(NSString*) nextOutput;
@end






