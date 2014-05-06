//
//  MBox.m
//  MailBoxes
//
//  Created by Taun Chapman on 04/24/14.
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
@dynamic maxCachedUID;
@dynamic lastSelected;
@dynamic lastSync;
@dynamic noInferiors;
@dynamic noSelect;
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
