//
//  MBController.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/6/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MBViewController;
@class MBWindowController;

@interface MBController : NSObject {
    NSManagedObjectContext *managedObjectContext;
    MBWindowController *mainWindow;
    MBViewController *mainViewController;

    NSManagedObject *selectedUser;

    NSArrayController *userArrayController;
    NSArrayController *currentAccountArrayController;
@private
    
}

@property(nonatomic, assign)    NSManagedObjectContext *managedObjectContext;

@property(retain) IBOutlet      MBWindowController *mainWindow;

@property(assign) IBOutlet      MBViewController *mainViewController;

@property(assign) IBOutlet      NSArrayController *userArrayController;

@property(assign) IBOutlet      NSArrayController *currentAccountArrayController;

@property(retain)               NSManagedObject *selectedUser;

- (IBAction)editAccounts:(id)sender;

@end
