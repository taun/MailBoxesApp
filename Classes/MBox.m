//
//  MBox.m
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBox.h"
#import "MBAccount.h"
#import "MBFlag.h"
#import "MBMessage.h"


@implementation MBox

@dynamic fullPath;
@dynamic isMarked;
@dynamic isReadWrite;
@dynamic lastSeenUID;
@dynamic lastSelected;
@dynamic lastSync;
@dynamic pathSeparator;
@dynamic serverHighestModSeq;
@dynamic serverMessages;
@dynamic serverRecent;
@dynamic serverUIDNext;
@dynamic serverUIDValidity;
@dynamic serverUnseen;
@dynamic specialUse;
@dynamic uid;
@dynamic accountReference;
@dynamic availableFlags;
@dynamic lastChangedMessage;
@dynamic messages;
@dynamic permanentFlags;

@end
