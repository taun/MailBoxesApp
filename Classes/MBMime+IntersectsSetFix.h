//
//  MBMime+IntersectsSetFix.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/01/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime.h"

@interface MBMime (IntersectsSetFix)
/*!
 The default code with core data for adding values to relationships where the relationship is represented by an ordered set is broken. The code uses NSSet with intersectsSet: rather than the NSOrderedSet equivalent. This is to fix the standard code and can be removed once the bug is fixed.
 
 @param value MBMime
 */
- (void)addChildNodesObject:(MBMime *)value;
- (void)addChildNodes:(NSOrderedSet *)values;

@end
