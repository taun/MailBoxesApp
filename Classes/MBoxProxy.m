//
//  MBoxProxy.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/18/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBoxProxy.h"

NSString * const MBPasteboardTypeMbox = @"com.moedae.mailboxes.mbox";

@implementation MBoxProxy

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - '%@' full path: %@, url: %@, desc: %@",
            [super description], self.name, self.fullPath, self.objectURL, self.desc];
}

- (instancetype) initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.objectURL = [coder decodeObjectForKey: @"objectURL"];
        self.name = [coder decodeObjectForKey: @"name"];
        self.desc = [coder decodeObjectForKey: @"desc"];
        self.fullPath = [coder decodeObjectForKey: @"fullPath"];
        self.uid = [coder decodeObjectForKey: @"uid"];
    }
    return self;
}

#pragma mark - Coding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject: [self.objectURL absoluteString] forKey: @"objectURL"];
    [coder encodeObject: self.name forKey:@"name"];
    [coder encodeObject: self.desc forKey:@"desc"];
    [coder encodeObject: self.fullPath forKey:@"fullPath"];
    [coder encodeObject: self.uid forKey:@"uid"];
}

#pragma mark - PasteboardReading
+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObject: MBPasteboardTypeMbox];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString: MBPasteboardTypeMbox]) {
        return NSPasteboardReadingAsKeyedArchive;
    } else if ([type isEqualToString: NSPasteboardTypeString]) {
        return NSPasteboardReadingAsString;
    } else {
        return 0;
    }
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    if ([type isEqualToString: MBPasteboardTypeMbox]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData: propertyList];
    } else if ([type isEqualToString: NSPasteboardTypeString]) {
        return propertyList;
    }
    return nil;
}

#pragma mark - PasteboardWriting
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
        return [NSArray arrayWithObjects: MBPasteboardTypeMbox, NSPasteboardTypeString, nil];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString: MBPasteboardTypeMbox]) {
        return [NSKeyedArchiver archivedDataWithRootObject: self];
    }
    else if ([type isEqualToString: NSPasteboardTypeString]) {
        return [self.objectURL absoluteString];
    }
    else {
        return nil; // Return nil if we are asked for a type we don't support
    }
}

@end
