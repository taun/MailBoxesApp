//
//  MBMessagesDesktopView.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/28/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MBMessagesDesktopView : NSView

@property (weak,nonatomic) IBOutlet NSController    *boundController;
@property (strong,nonatomic) NSString               *contentBindingKeyPath;
@property (strong,nonatomic) NSString               *selectionIndexesBindingKeyPath;
@property (strong,nonatomic) IBOutlet id            itemPrototype;
@property (strong,nonatomic)          NSArray       *content;
@property (strong,nonatomic)          NSIndexSet    *selectionIndexes;


-(void) tile;
@end
