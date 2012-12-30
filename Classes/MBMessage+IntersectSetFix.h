//
//  MBMessage+IntersectSetFix.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/07/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessage.h"

@interface MBMessage (IntersectSetFix)

- (void)addChildNodesObject:(MBMime *)value;
- (void)addChildNodes:(NSOrderedSet *)values;

@end
