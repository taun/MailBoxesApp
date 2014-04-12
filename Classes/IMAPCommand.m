//
//  IMAPCommand.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/19/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPCommand.h"
#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"

@interface IMAPCommand () 
@property (strong)  NSMutableArray*     arguments;
@property (assign)  BOOL                sentArguments;
@end

@implementation IMAPCommand

@synthesize atom;
@synthesize tag;
@synthesize info;
@synthesize mbox;
@synthesize mboxFullPath;
@synthesize arguments;
@synthesize isActive;
@synthesize isDone;
@synthesize hasLiteral;
@synthesize literal;
@synthesize responseStatus;

-(id)initWithAtom:(NSString *)commandString{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.atom = commandString;
        tag = nil;
        info = nil;
        mbox = nil;
        mboxFullPath = nil;
        isActive = NO;
        isDone = NO;
        hasLiteral = NO;
        literal = nil;
        arguments = nil;
        responseStatus = 0;
        _sentArguments = NO;
    }
    
    return self;
}

#pragma message "TODO: add init method which passes and empty string to designated initializer"

-(void)copyAddArgument:(NSString *)anArgument{
    if(self.arguments == nil){
    
        self.arguments = [[NSMutableArray alloc] initWithCapacity: 1];
    }
    [self.arguments addObject: [anArgument copy]];
}

-(NSString*) nextOutput {
    NSString *outputString, *trimmedString, *commandString;
    
    if (!self.sentArguments) {
        NSString* argumentString = @"";
        if (self.arguments && (self.arguments.count > 0)) {
            argumentString = [self.arguments componentsJoinedByString:@" "];
        }
        commandString = [NSString stringWithFormat:@"%@ %@ %@",
                         tag, [atom uppercaseString], argumentString];
        trimmedString = [commandString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        outputString = [trimmedString stringByAppendingString: @"\n"];
        self.sentArguments = YES;
    }

    return outputString;
}

- (NSString*) debugDescription {
    NSString* theDescription = [NSString stringWithFormat:@" (atom: %@, tag: %@, responseStatus: %@, info: %@, isActive: %u, isDone: %u,hasLiteral: %u)",
                                self.atom, self.tag, [IMAPParsedResponse statusAsString: self.responseStatus], self.info, self.isActive, self.isDone, self.hasLiteral];
    return theDescription;
}
@end
