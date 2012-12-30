//
//  MBMime+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/06/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime+IMAP.h"
#import "MBMimeData+IMAP.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

@implementation MBMime (IMAP)

#pragma mark - encoding decoding

- (void)encodeWithCoder:(NSCoder *)coder {

    NSURL* objectURL = [[self objectID] URIRepresentation];
    [coder encodeObject: [objectURL absoluteString] forKey: @"managedObjectURL"];
    [coder encodeObject: self.bodyIndex forKey:@"bodyIndex"];
    [coder encodeObject: self.subPartNumber forKey:@"subPartNumber"];
    [coder encodeObject: self.charset forKey:@"charset"];
    [coder encodeObject: self.desc forKey:@"desc"];
    [coder encodeObject: self.encoding forKey:@"encoding"];
    [coder encodeObject: self.extensions forKey:@"extensions"];
    [coder encodeObject: self.id forKey:@"id"];
    [coder encodeObject: self.isAttachment forKey:@"isAttachment"];
    [coder encodeObject: self.isInline forKey:@"isInline"];
    [coder encodeObject: self.language forKey:@"language"];
    [coder encodeObject: self.lines forKey:@"lines"];
    [coder encodeObject: self.location forKey:@"location"];
    [coder encodeObject: self.md5 forKey:@"md5"];
    [coder encodeObject: self.name forKey:@"name"];
    [coder encodeObject: self.octets forKey:@"octets"];
    [coder encodeObject: self.subtype forKey:@"subtype"];
    [coder encodeObject: self.type forKey:@"type"];
    [coder encodeObject: self.childNodes forKey:@"childNodes"];
}

- (void) addEncodedData:(NSString *)encodedData {
    MBMimeData* mimeData = [NSEntityDescription
                            insertNewObjectForEntityForName: @"MBMimeData"
                            inManagedObjectContext: self.managedObjectContext];
    mimeData.encoded = encodedData;
    mimeData.encoding = self.encoding;
    mimeData.mimeStructure = self;
}

-(NSArray*) childNodesArray {
    return [self.childNodes array];
}
-(NSSet*) childNodesSet {
    return [self.childNodes set];
}

@end
