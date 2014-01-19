//
//  MBMessageHeaderView.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMessageHeaderView.h"
#import "MBAddress+IMAP.h"
#import "MBAddressList.h"
#import "NSString+IMAPConversions.h"

@implementation MBMessageHeaderView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void) awakeFromNib {
//    [self setBoxType: NSBoxCustom];
//    [self setCornerRadius: 0.0];
//    [self setFillColor: [NSColor whiteColor]];
//    [self setBorderColor: [NSColor grayColor]];
//    [self setBorderWidth: 0.0];
//    [self setTitlePosition: NSNoTitle];
}

-(void) setMessage:(MBMessage *)message {
    if (message != _message) {
        _message = message;
        //        [_message addObserver: self forKeyPath: @"defaultContent" options: NSKeyValueObservingOptionNew context: NULL];
        if (_message) {
//            self.title = self.message.subject;
        }
    }
    [self refreshMessageDisplay: nil];
}

- (IBAction)refreshMessageDisplay:(id)sender {
    if (self.message.addressFrom) {
        [self.sender setStringValue: [self.message.addressFrom stringRFC822AddressFormat]];
    }
    
    [self.dateSent setObjectValue: self.message.dateSent];
    
    if ([self.message.addressesTo count]>0) {
        [self.recipients setStringValue: [self stringFromAddresses: self.message.addressesTo]];
    }
    
    [self.subject setStringValue: self.message.subject];
}

-(NSString*) stringFromAddresses:(NSSet *)addresses {
    NSMutableString* addressesAsString = [NSMutableString new];
    for (MBAddress* address in addresses) {
        if ([addresses isKindOfClass:[MBAddress class]]) {
            [addressesAsString appendString: [address stringRFC822AddressFormat]];
        }
    }
    return addressesAsString;
}

@end
