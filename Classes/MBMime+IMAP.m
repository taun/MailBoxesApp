//
//  MBMime+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/06/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime+IMAP.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"


static const int ddLogLevel = LOG_LEVEL_WARN;


NSString* MBRichMessageViewAttributeName = @"MBRichMessageView";

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
    // need to add encoding of self.data?
}

- (void) addEncodedData:(NSString *)encodedData {
    MBMimeData* mimeData = [NSEntityDescription
                            insertNewObjectForEntityForName: @"MBMimeData"
                            inManagedObjectContext: self.managedObjectContext];
    mimeData.encoded = encodedData;
    mimeData.encoding = self.encoding;
    [mimeData setMimeStructure: self];
}
-(void) decoder {
}
-(BOOL) decode {
    if (![self.data.isDecoded boolValue] && self.data.encoded != nil){
        [self decoder];
        if ([self.data.isDecoded boolValue] && (self.data.decoded != nil)) {
            self.data.encoded = nil;
        }
    }
    return [self.data.isDecoded boolValue];
}
-(NSData*) getDecodedData {
    NSData* decodedData;
    if ([self decode]) {
        decodedData = self.data.decoded;
    }
    return decodedData;
}
-(NSArray*) childNodesArray {
    return [self.childNodes array];
}
-(NSSet*) childNodesSet {
    return [self.childNodes set];
}

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];

    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}

-(BOOL) hasRichMessageViewOption:(NSDictionary *)options {
    BOOL useRichMessageView = NO;
    
    id useRichMessageViewOption = options[MBRichMessageViewAttributeName];
    
    if (useRichMessageViewOption && [useRichMessageViewOption isKindOfClass: [NSNumber class]]) {
        useRichMessageView = [(NSNumber*)useRichMessageViewOption boolValue];
    }
    
    return useRichMessageView;
}

@end
