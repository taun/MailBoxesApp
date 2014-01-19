//
//  MBMessagesLayoutViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesLayoutViewController.h"

@interface MBMessagesLayoutViewController ()

@property (nonatomic,strong) NSMutableArray*    messages;

-(void) layoutMessages;

-(void) layoutMessage: (MBMessage*) message;

@end

@implementation MBMessagesLayoutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void) contain:(MBMessage *)currentMessage {
    [self.messages removeAllObjects];
    [self.messages addObject: currentMessage];
}

-(void) contains:(NSArray *)currentMessages {
    [self.messages removeAllObjects];
    [self.messages addObjectsFromArray: currentMessages];
}

-(void) layoutMessages {
    for (MBMessage* message in self.messages) {
        [self layoutMessage: message];
    }
}

-(void) layoutMessage:(MBMessage *)message {
//    self.messageViewController = [[MBMessageViewController alloc] initWithNibName: @"MBMessageViewController" bundle: nil];
//    self.messageViewController.view.frame = NSMakeRect(0, 0, contentSize.width, contentSize.height);
//    self.messageViewController.message = selectedMessage;
//    
//    
//    [self.inPaneMessageView setDocumentView: self.messageViewController.view];
//    NSView* messageView = [self.inPaneMessageView documentView];
//    NSRect oldFrame = messageView.frame;
//    messageView.frame = NSMakeRect(0, 200, oldFrame.size.width, oldFrame.size.height);
//    

}
@end
