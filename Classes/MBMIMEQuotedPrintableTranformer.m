//
//  MBMIMEQuotedPrintableTranformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/15/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIMEQuotedPrintableTranformer.h"
#import "MBEncodedString.h"
#import "NSString+IMAPConversions.h"


@implementation MBMIMEQuotedPrintableTranformer


-(id) transformedValue:(id)anMBEncodedString {
    MBEncodedString* dequotedPrintable;
    
    if ([anMBEncodedString isKindOfClass:[MBEncodedString class]]) {
        //
        NSString* qpString = ((MBEncodedString*)anMBEncodedString).string;
        NSStringEncoding encoding = ((MBEncodedString*)anMBEncodedString).encoding;
        
        dequotedPrintable.string = [qpString mdcStringDeQuotedPrintableFromCharset: encoding];
        dequotedPrintable.encoding = encoding;
    }
    return dequotedPrintable;
}


//-(id) transformedValue:(id)value {
//    NSMutableString* decodedString = [NSMutableString new];
//
//    if ([value isKindOfClass: [NSString class]] && value != nil) {
//        NSString* encodedString = (NSString*) value;
//        
//        NSUInteger lineStartIndex;
//        NSUInteger lineEndIndex;
//        NSUInteger lineContentsEndIndex;
//        
//        NSRange testLineRange = NSMakeRange(0, 3);
//        
//        do {
//            [encodedString getLineStart: &lineStartIndex
//                                    end: &lineEndIndex
//                            contentsEnd: &lineContentsEndIndex
//                               forRange: testLineRange];
//            
//            NSRange lineRange = NSMakeRange(lineStartIndex, lineContentsEndIndex-lineStartIndex);
//            NSString* lineString = [encodedString substringWithRange: lineRange];
//            
//            NSString* decodedLineString = [self decodeOneLine: lineString];
//            [decodedString appendString: decodedLineString];
            
//            NSString* lastCharacterEndString = [encodedString substringWithRange: NSMakeRange(lineContentsEndIndex-1, 1)];
//            NSString* last3CharactersEndString = [encodedString substringWithRange: NSMakeRange(lineContentsEndIndex-3, 3)];
//            
//            if ([lastCharacterEndString isEqualToString: @"="]) {
//                // remove "=" and append
//                [decodedString appendString: [lineString substringToIndex: lineString.length-1]];
//                
//            } else if ([last3CharactersEndString isEqualToString: @"=20"]) {
//                // replace =20 with hard return
//                [decodedString appendString: [lineString substringToIndex: lineString.length-3]];
//                [decodedString appendString: @"\n"];
//            } else {
//                [decodedString appendString: [lineString substringToIndex: lineString.length]];
//                [decodedString appendString: @"\n"];
//            }
//            testLineRange = NSMakeRange(lineEndIndex, 3);
//        } while (lineContentsEndIndex < (encodedString.length - 2));
// 
//    }
//    
//    return [decodedString copy];
//}

@end
