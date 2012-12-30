//
//  MBox.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/19/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBox.h"
#import "MBAccount.h"
#import "MBFlag.h"
#import "MBMessage.h"
#import "MBSmartFolder.h"


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
@dynamic criteria;
@dynamic lastChangedMessage;
@dynamic messages;
@dynamic permanentFlags;

@end
