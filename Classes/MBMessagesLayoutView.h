//
//  MBMessagesLayoutView.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 Responsible for laying out one or more views.
 
 Usually to be used within an NSScrollView as the Document.
 
 Places messages at the top left corner of the view.
 
 If multiple messages, they are laid out descending vertically
 
 View Structure should be:
 
    MBMessagesLayoutView
        MBMMessageView
            MBMessageHeaderView
            MBMessagePlainView:MBMimeView
            MBAttachmentsView
            ...
        MBMMessageView
            MBMessageHeaderView
            ...
 
 */
@interface MBMessagesLayoutView : NSView

@property (nonatomic,strong) NSMutableArray*    messages;

@end
