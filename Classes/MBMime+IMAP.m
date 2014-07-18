//
//  MBMime+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/06/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime+IMAP.h"
#import "NSManagedObject+Shortcuts.h"



static const int ddLogLevel = LOG_LEVEL_WARN;


@implementation MBMime (IMAP)



#pragma mark - encoding decoding

-(MMPMimeProxy*) asMimeProxy {
    MMPMimeProxy* mimeProxy = [MMPMimeProxy new];
    mimeProxy.objectID = self.objectID;
    mimeProxy.bodyIndex = self.bodyIndex;
    mimeProxy.subPartNumber = self.subPartNumber;
    mimeProxy.charset = self.charset;
    mimeProxy.desc = self.desc;
    mimeProxy.encoding = self.encoding;
    mimeProxy.extensions = self.extensions;
    mimeProxy.id = self.id;
    mimeProxy.isAttachment = self.isAttachment;
    mimeProxy.isInline = self.isInline;
    mimeProxy.isLeaf = self.isLeaf;
    mimeProxy.language = self.language;
    mimeProxy.lines = self.lines;
    mimeProxy.location = self.location;
    mimeProxy.md5 = self.md5;
    mimeProxy.name = self.name;
    mimeProxy.subtype = self.subtype;
    mimeProxy.type = self.type;
    mimeProxy.encoded = self.data.encoded;
    mimeProxy.decoded = [self getDecodedData];
    // order is important getDecodedData needs to be before isDecoded
    // getDecodedData is a lazy decoding which sets the isDecoded flag if successfull
    mimeProxy.isDecoded = self.data.isDecoded;
    
    if ([[self mappedChildNodes] count] > 0) {
        NSMutableOrderedSet* childNodes = [NSMutableOrderedSet new];
        for (MBMime* child in [self mappedChildNodes]) {
            [childNodes addObject: [child asMimeProxy]];
        }
        mimeProxy.childNodes = [childNodes copy];
    }
    
    return mimeProxy;
}

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
    [coder encodeObject: self.isLeaf forKey:@"isLeaf"];
    [coder encodeObject: self.language forKey:@"language"];
    [coder encodeObject: self.lines forKey:@"lines"];
    [coder encodeObject: self.location forKey:@"location"];
    [coder encodeObject: self.md5 forKey:@"md5"];
    [coder encodeObject: self.name forKey:@"name"];
    [coder encodeObject: self.octets forKey:@"octets"];
    [coder encodeObject: self.subtype forKey:@"subtype"];
    [coder encodeObject: self.type forKey:@"type"];
    [coder encodeObject: self.childNodes forKey:@"childNodes"]; // how to handle mappedChildNodes of MBMimeMessage
    // need to add encoding of self.data?
}

- (void) addEncodedData:(NSString *)encodedData {
    MBMimeData* mimeData = [MBMimeData insertNewObjectIntoContext: self.managedObjectContext];
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
#pragma message "TODO add cache for _allChildNodes"
#pragma message "TODO change from recursive algorithm"
-(NSSet*) allChildNodes {
    NSMutableSet* _allChildNodes = [NSMutableSet setWithCapacity: self.childNodes.count];
    for (MBMime* node in self.childNodes) {
        [_allChildNodes unionSet: [node allChildNodes]];
    }
    [_allChildNodes addObject: self];
    return [_allChildNodes copy];
}
-(NSSet*) allChildNodesWithContentPotential {
    NSSet* _allChildNodes = [self allChildNodes];
    NSMutableSet* _allChildNodesWithContentPotential = [NSMutableSet setWithCapacity: _allChildNodes.count];
    for (MBMime* node in _allChildNodes) {
        if ([node.isLeaf boolValue]) {
            [_allChildNodesWithContentPotential addObject: node];
        }
    }
    return [_allChildNodesWithContentPotential copy];
}
-(NSSet*) allChildNodeAttachments {
    NSSet* _allChildNodes = [self allChildNodes];
    NSMutableSet* _allChildNodeAttachments = [NSMutableSet setWithCapacity: _allChildNodes.count];
    for (MBMime* node in _allChildNodes) {
        if ([node.isAttachment boolValue]) {
            [_allChildNodeAttachments addObject: node];
        }
    }
    return [_allChildNodeAttachments copy];
}
-(NSSet*) allChildNodesMissingContent {
    NSSet* _allChildNodesWithContentPotential = [self allChildNodesWithContentPotential];
    NSMutableSet* _allChildNodesMissingContent = [NSMutableSet setWithCapacity: _allChildNodesWithContentPotential.count];
    for (MBMime* node in _allChildNodesWithContentPotential) {
        if (node.data == nil) {
            [_allChildNodesMissingContent addObject: node];
        }
    }
    return [_allChildNodesMissingContent copy];
}
-(NSOrderedSet*) mappedChildNodes {
    return self.childNodes;
}
-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];

    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}


@end
