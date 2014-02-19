//
//  MBPortalsCollectionViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/19/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBPortalsCollectionView.h"
#import "MBUser+IMAP.h" // not sure we need more than just MBUser.h

/*
 Unused
 
 Thinking of moving some of MBPortalsCollectionView to here.
 Similar to MBSidebarViewController
 */
@interface MBPortalsCollectionViewController : NSObject <NSCollectionViewDelegate, MBPortalsCollectionDelegate>

@property (unsafe_unretained) IBOutlet NSObjectController       *userController;
@property (readonly, weak)          MBUser                      *currentUser;
@property (weak) IBOutlet           NSCollectionView            *view;


@end
