//
//  MBController.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/6/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import "MBController.h"
#import "MBViewController.h"
#import "MBWindowController.h"


@implementation MBController

@synthesize managedObjectContext;
@synthesize mainWindow;
@synthesize mainViewController;
@synthesize selectedUser;
@synthesize userArrayController;
@synthesize currentAccountArrayController;

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
        mainWindow = [[MBWindowController  alloc] initWithNib: @"MailBoxes" 
                                         managedObjectContext: self.managedObjectContext 
                                                         user: self.selectedUser];
        [mainWindow showWindow: self];
    }
    
    return self;
}

- (IBAction)editAccounts:(id)sender {
    self.selectedUser = [userArrayController selection];
    
    MBWindowController *accountsWindowController = [[[MBWindowController alloc] initWithNib: @"MBAddAccount" 
                                                                       managedObjectContext: self.managedObjectContext 
                                                                                       user: self.selectedUser] autorelease];

    // set accounts controller context/binding as currentUser?
    [accountsWindowController showWindow: self];
}

- (void)dealloc {
    // Clean-up code here.
    
    [selectedUser release];
    [mainViewController release];
    [managedObjectContext release];
    [super dealloc];
}

@end
