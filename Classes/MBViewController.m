//
//  MailBoxesViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/20/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import "MBViewController.h"

@implementation MBViewController

@synthesize managedObjectContext;


- (int)messageQuanta {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"MessageQuanta"];
}

- (void)dealloc {  
    [managedObjectContext release];
    [super dealloc];
}
@end
