//
//  RFC2822RawMessageHeader.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "RFC2822RawMessageHeader.h"

static NSRegularExpression *regexHeaderField;


@interface RFC2822RawMessageHeader ()
@end

@implementation RFC2822RawMessageHeader

@synthesize unfolded;
@synthesize fields;

+(void)initialize {
    NSError *error=nil;
    regexHeaderField = [[NSRegularExpression alloc] initWithPattern: @"^(\\S+):\\s(.*)"
                                                           options: (NSRegularExpressionAnchorsMatchLines | NSRegularExpressionCaseInsensitive)
                                                             error: &error];
}

- (id)initWithString:(NSString *)rawString
{
    self = [super init];
    if (self) {
        // Initialization code here.
        unfolded = [self _unfold: rawString];
        fields = [[NSMutableDictionary alloc] initWithCapacity: 10];
        [self _identifyFields];
    }
    
    return self;
}
#pragma message "ToDo: convert to use c strings?"
/*!
 Private - MIME Unfolding
 
 Just use regex to look for space at the begining of a line.
 Where ever there is space, remove the preceeding crlf.
 
 If character is ' ' or '\t' and preceding character is '\n' skip character
 
 @param rawString raw header string including newlines and indentations
 @returns unfolded NSString
 */
-(NSString *) _unfold: (NSString *) rawString {
    
    return [rawString stringByReplacingOccurrencesOfString: @"\\r\\n\\s+" 
                                                withString: @" " 
                                                   options: NSRegularExpressionSearch
                                                     range: NSMakeRange(0, [rawString length])];
}

-(void) _identifyFields {
    
    [regexHeaderField enumerateMatchesInString: self.unfolded 
                                       options:0 
                                         range: NSMakeRange(0, [self.unfolded length]) 
                                    usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                                        
                                        NSString *field = nil;
                                        NSString *value = nil;
                                        
                                        if (match.numberOfRanges==3) {
                                            field = [[self.unfolded substringWithRange: [match rangeAtIndex: 1]] uppercaseString];
                                            value = [self.unfolded substringWithRange: [match rangeAtIndex: 2]];
                                            (self.fields)[field] = value;
                                        }
    }];
}

@end
