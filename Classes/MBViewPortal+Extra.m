//
//  MBViewPortal+Extra.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBViewPortal+Extra.h"

@implementation MBViewPortal (Extra)

+ (NSString *)entityName {
    return @"MBViewPortal";
}


+(NSString*) classTitle {
    return NSStringFromClass([self class]);
}

+(NSSet *) keyPathsForValuesAffectingTitle{
    return [NSSet setWithObjects: @"name" , nil];
}

-(NSString*) title {
    return [NSString stringWithFormat: @"%@: %@", [[self class] classTitle], self.name];
}

@end

