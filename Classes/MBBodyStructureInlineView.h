//
//  MBBodyStructureInlineView.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/27/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBMessage+IMAP.h"

/*!
 Responsible for displaying the bodyStructure of a message.
 
 This is a top level container view.

 The body structure consists of all of the possible mime types.
 Each mime type has it's own view but all should conform to a protocol.
 
 BodyStructureInlineView
    PlainText Mime - Show or hide depending on preference or action
    RichText Mime - Show or hide depending on preference or action
    PDFMime - Inline or as icon depending on preference or action
    Application Mime - Inline or as icon depending on preference or action
    RawMime - As above
 
 How to handle nested mimes?
 
 Where to show attachments summary? top? bottom? both?
 
 Controls for hiding and showing mimes?
 
 Recurse through mime parts.
 Lookup each part in the plugin registry based on type.subtype.
 Set options and attributes.
 
 
 */
@interface MBBodyStructureInlineView : NSView

@property (nonatomic,strong) MBMessage* message;

@end
