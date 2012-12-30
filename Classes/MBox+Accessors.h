//
//  MBox+Accessors.h
//  MailBoxes
//
//  Created by Taun Chapman on 2/25/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBox.h"

@interface MBox (Accessors)

- (void)setPrimitiveFullPath: (NSString *) value;
- (void)setPrimitiveName: (NSString *) value;
- (void)setPrimitiveIsLeaf: (NSNumber *) value;
- (void)setPrimitiveAccount: (MBAccount *) value;
- (void)setPrimitiveParentNode: (MBox *) value;


@end
