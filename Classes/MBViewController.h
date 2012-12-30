//
//  MailBoxesViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/20/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBViewController : NSViewController {

    NSManagedObjectContext *managedObjectContext;

@private
    
}

@property(nonatomic, assign) NSManagedObjectContext *managedObjectContext;


- (int)messageQuanta;


@end
