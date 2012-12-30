//
//  MBAccount+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 2/22/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBAccount.h"

@class MBox;

#define MBAccountImageName @"mailboxes_16"

/*!
 @header
 
 more later
 
 */

/*!
 @category MBAccount(IMAP)
 Category to add functionality for handling IMAP
 */
@interface MBAccount (IMAP) 

/*!
 for cut and paste functionality
 */
+ (NSArray *)keysToBeCopied;

/*!
 
 Check if the MBox on the path already exists.
             If so, return the MBox
             If not, create necessary elements of the path and the MBox
 
 @param path  the path as passed from the imap server
 @param separator the separator used by the imap server
 @param createIntermediates flag to indicate whether to create the 
 intermediate MBoxes if they do not already exist.
 
 @result the new MBox node in the account heirarchy or nil if there was a problem.
 */
- (MBox *)getMBoxAtPath:(NSString *)path 
             withSeparator: (NSString *)separator 
    createIntermediateMBoxes:(BOOL)createIntermediates;

- (MBox *) fetchMBoxForPath: (NSString *) aPath;

//-(NSError *) saveChanges;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)initWithCoder: (NSCoder *)coder;

- (NSUInteger)count;

@end

