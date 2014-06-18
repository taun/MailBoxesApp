//
//  MMPMimeHeaderView.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MMPMimeHeaderView.h"
#import "MBSimpleRFC822AddressToStringTransformer.h"

#define MBKFontSizeFactor 1.2

@implementation MMPMimeHeaderView

#pragma message "TODO: refactor attributes code from here and MBEnrichedTextParser into one class for reuse."
-(NSMutableDictionary*) changeAlignmentIn: (NSMutableDictionary*) newAttributes to: (NSTextAlignment) alignment {

    NSParagraphStyle* currentStyle = [newAttributes objectForKey: NSParagraphStyleAttributeName];
    
    NSMutableParagraphStyle* style;
    
    
    if (currentStyle) {
        style = [currentStyle mutableCopy];
    } else {
        style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    }
    
    [style setAlignment: alignment];
    
    
    if (style) {
        [newAttributes setObject: style forKey: NSParagraphStyleAttributeName];
    }
    
    return newAttributes;
}

-(NSMutableDictionary*) centerAttributes: (NSMutableDictionary*)defaultAttributes {
    return [self changeAlignmentIn: defaultAttributes to: NSCenterTextAlignment];
}
-(NSMutableDictionary*) rightAttributes: (NSMutableDictionary*)defaultAttributes {
    return [self changeAlignmentIn: defaultAttributes to: NSRightTextAlignment];
}
-(NSMutableDictionary*) leftAttributes: (NSMutableDictionary*)defaultAttributes {
    return [self changeAlignmentIn: defaultAttributes to: NSLeftTextAlignment];
}

-(NSFont*) getFont: (NSMutableDictionary*)newAttributes  {
    
    NSFont* font = [newAttributes objectForKey: NSFontAttributeName];
    if (!font) {
        // get default font
        NSFontManager* aFontManager = [NSFontManager sharedFontManager];
        font = [aFontManager fontWithFamily: @"Helvetica" traits: (NSUnboldFontMask | NSUnitalicFontMask) weight: 5 size: 12];
    }
    
    return font;
}

-(NSMutableDictionary*) italicAttributes: (NSMutableDictionary*)newAttributes {
    // change to italic
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont: newAttributes];
    NSFont* italicFont = [aFontManager convertFont: font toHaveTrait: NSItalicFontMask];
    [newAttributes setObject: italicFont forKey: NSFontAttributeName];
    return newAttributes;
}

-(NSMutableDictionary*) biggerAttributes: (NSMutableDictionary*)newAttributes  {
    // change to italic
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont: newAttributes];
    NSFont* biggerFont = [aFontManager convertFont: font toSize: [font pointSize] * MBKFontSizeFactor];
    [newAttributes setObject: biggerFont forKey: NSFontAttributeName];
    return newAttributes;
}
-(NSMutableDictionary*) grayColorAttributes: (NSMutableDictionary*)newAttributes {
    
    NSColor* color = [NSColor grayColor];
    
    if (color) {
        [newAttributes setObject: color forKey: NSForegroundColorAttributeName];
    }
    return newAttributes;
}


-(void) loadData {
    NSMutableAttributedString* composition;
    MBSimpleRFC822AddressToStringTransformer* transformer = (MBSimpleRFC822AddressToStringTransformer*)[NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressToStringTransformer];
    
    NSDictionary* attributes = self.options.attributes;
    NSMutableDictionary* newAttributes = [attributes mutableCopy];
    
    if (!newAttributes) {
        newAttributes = [NSMutableDictionary new];
    }
    
    NSMutableDictionary* labelAttributes = [newAttributes mutableCopy];
    [self leftAttributes: labelAttributes];
    [self grayColorAttributes: labelAttributes];
    
    composition = [[NSMutableAttributedString alloc] initWithString: @"Included Message:\n" attributes: labelAttributes];
    
    if (self.node.addressFrom) {
        NSMutableDictionary* addressAttributes = [self rightAttributes: [newAttributes mutableCopy]];
        NSString* fromString = [NSString stringWithFormat: @"%@\n", [transformer transformedValue: self.node.addressFrom]];
        [composition appendAttributedString: [[NSMutableAttributedString alloc] initWithString: fromString attributes: addressAttributes]];
    }
    if (self.node.addressesTo != nil) {
        NSMutableDictionary* addressAttributes = [self leftAttributes: [newAttributes mutableCopy]];
        NSString* toString = [NSString stringWithFormat: @"%@\n", [transformer transformedValue: self.node.addressesTo]];
        [composition appendAttributedString: [[NSMutableAttributedString alloc] initWithString: toString attributes: addressAttributes]];
    }
    if (self.node.subject != nil) {
        NSMutableDictionary* subjectAttributes = [self leftAttributes: [newAttributes mutableCopy]];
        [self italicAttributes: subjectAttributes];
        [self biggerAttributes: subjectAttributes];
        NSString* subjectString = [NSString stringWithFormat: @"%@\n", [transformer transformedValue: self.node.subject]];
        [composition appendAttributedString: [[NSMutableAttributedString alloc] initWithString: subjectString attributes: subjectAttributes]];
    }
    
    [[(NSTextView*)(self.mimeView) textStorage] setAttributedString: composition];
    
    [self setNeedsUpdateConstraints: YES];
}

-(void) updateConstraints {
    [self.mimeView setContentHuggingPriority: 150 forOrientation: NSLayoutConstraintOrientationHorizontal]; // was 1000
    [super updateConstraints];
}

@end
