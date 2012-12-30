//
//  MDLAppDelegate.h
//  mailboxes
//
//  Created by Taun Chapman on 12/29/12.
//  Copyright (c) 2012 Taun Chapman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MDLAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
