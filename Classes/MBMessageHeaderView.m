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

@implementation MBMessageHeaderView

//-(NSSize) intrinsicContentSize {
//    CGFloat height = self.frame.size.height;
//    NSSize newSize = NSMakeSize(NSViewNoInstrinsicMetric, height);
//    return newSize;
//}
//
//-(void) removeSubviews {
//}
//
//-(void) createSubviews {
//    if (self.node.addressFrom) {
//        [self.sender setStringValue: [self.node.addressFrom stringRFC822AddressFormat]];
//    }
//    
////    [self.dateSent setObjectValue: self.node.dateSent];
//    
//    if (self.node.addressesTo) {
//        [self.recipients setStringValue: [self.node.addressesTo stringRFC822AddressFormat]];
//    }
//    
//    [self.subject setStringValue: self.node.subject];
//    [self removeConstraints: self.constraints];
//    [self setNeedsUpdateConstraints: YES];
//}

@end
