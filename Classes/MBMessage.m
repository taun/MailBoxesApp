//
//  MBMessage.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/13/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMessage.h"
#import "MBAddress.h"
#import "MBAttachment.h"
#import "MBFlag.h"
#import "MBLabel.h"
#import "MBMime.h"
#import "MBRFC2822.h"
#import "MBox.h"


@implementation MBMessage

@dynamic dateReceived;
@dynamic dateSent;
@dynamic encoding;
@dynamic hasAttachment;
@dynamic isAnsweredFlag;
@dynamic isDeletedFlag;
@dynamic isDraftFlag;
@dynamic isFlaggedFlag;
@dynamic isFullyCached;
@dynamic isRecentFlag;
@dynamic isSeenFlag;
@dynamic messageId;
@dynamic organization;
@dynamic rfc2822Size;
@dynamic sequence;
@dynamic subject;
@dynamic summary;
@dynamic uid;
@dynamic addressesBcc;
@dynamic addressesCc;
@dynamic addressesTo;
@dynamic addressFrom;
@dynamic addressReplyTo;
@dynamic addressSender;
@dynamic allParts;
@dynamic attachments;
@dynamic childNodes;
@dynamic flags;
@dynamic labels;
@dynamic lastChanged;
@dynamic mbox;
@dynamic rfc2822;

@end
