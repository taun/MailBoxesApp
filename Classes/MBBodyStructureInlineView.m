//
//  MBBodyStructureInlineView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/27/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBBodyStructureInlineView.h"
#import "MBMime+IMAP.h"

#import "MDLTextViewIntrinsic.h"

@interface MBBodyStructureInlineView ()

// quick and dirty, should use a view tag here or array
@property (nonatomic, strong) NSTextView* subTextView;

-(void) generateViewLayout;

-(NSAttributedString*) attributedStringFromMessage: (MBMessage*) message;

@end

@implementation MBBodyStructureInlineView

-(void) awakeFromNib {
    [self generateViewLayout];
    [self addObserver: self forKeyPath: @"message" options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context: NULL];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"message"]) {
        [self setBodyContent];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) dealloc {
    [self removeObserver: self forKeyPath: @"message"];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self.subTextView];
}

//-(void) layout {
////    [self.subTextView setConstrainedFrameSize: NSMakeSize(self.frame.size.width - 10, self.frame.size.height - 16)];
//    [super layout];
//    NSSize textSize = self.subTextView.frame.size;
////    self.subTextView.frame = NSMakeRect(0, 0, textSize.width, textSize.height);
//    NSRect frame = self.frame;
//    self.frame = NSMakeRect(frame.origin.x, frame.origin.y,
//                            frame.size.width, textSize.height+16);
//    [super layout];
//}

-(void) updateConstraints {
    
    // last
    [super updateConstraints];
}

//-(void) viewWillStartLiveResize {
//    [super viewWillStartLiveResize];
//}

//-(void) viewDidEndLiveResize {
//    [super viewDidEndLiveResize];
//    [self removeConstraints: self.constraints];
//    [self.subTextView removeConstraints: self.subTextView.constraints];
//    [self setNeedsUpdateConstraints: YES];
//}

-(void) setBodyContent {
    if (0) {
        NSString* par1 = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
        NSString* par2 = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?";
        //    NSString* sample = [NSString stringWithFormat: @"%@", par1];
        //    NSAttributedString* content = [[NSAttributedString alloc] initWithString: sample];
        NSAttributedString* content = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\r\n\r\n%@\r\n\r\n%@\r\n\r\n%@\r\n\r\n%@", par1, par2, par1, par2, par1]];
        
        //    [[rawMime textStorage] setAttributedString: [self attributedStringFromMessage: self.message]];
        [[self.subTextView textStorage] setAttributedString: content];
    } else {
        [[self.subTextView textStorage] setAttributedString: [self attributedStringFromMessage: self.message]];
    }
    [self.subTextView setNeedsLayout: YES];
}
/*!
 Need to replace the below with a self contained subview based on message components.
 */
-(void) generateViewLayout {
    NSSize subStructureSize = self.frame.size;
    
    NSTextView* rawMime = [[MDLTextViewIntrinsic alloc] initWithFrame: NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height)];
    // View in nib is min size. Therefore we can use nib dimensions as min when called from awakeFromNib
    [rawMime setMinSize: NSMakeSize(subStructureSize.width, subStructureSize.height)];
    [rawMime setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [rawMime setVerticallyResizable: YES];
    
    // No horizontal scroll version
//    [rawMime setHorizontallyResizable: YES];
//    [rawMime setAutoresizingMask: NSViewWidthSizable];
//    
//    [[rawMime textContainer] setContainerSize: NSMakeSize(subStructureSize.width, FLT_MAX)];
//    [[rawMime textContainer] setWidthTracksTextView: YES];
    
    // Horizontal resizable version
    [rawMime setHorizontallyResizable: YES];
//    [rawMime setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
    
    [[rawMime textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [[rawMime textContainer] setWidthTracksTextView: YES];
    [self addSubview: rawMime];

    [rawMime setTranslatesAutoresizingMaskIntoConstraints: NO];

//    NSDictionary *views = NSDictionaryOfVariableBindings(self, rawMime);

//    [self setContentCompressionResistancePriority: NSLayoutPriorityFittingSizeCompression-1 forOrientation: NSLayoutConstraintOrientationVertical];
    //NSLayoutPriorityDefaultHigh
    
    CALayer* rawLayer = rawMime.layer;
    [rawLayer setBorderWidth: 2.0];
    [rawLayer setBorderColor: [[NSColor blueColor] CGColor]];
    

    CALayer* myLayer = self.layer;
    [myLayer setBorderWidth: 2.0];
    [myLayer setBorderColor: [[NSColor redColor] CGColor]];

    self.subTextView = rawMime;
    
    [self addConstraints:@[
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant: 0],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                         constant: 0],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant: 0],
                           
                           [NSLayoutConstraint constraintWithItem: self.subTextView
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1
                                                         constant: 0],
                           
                           ]];
    
    [self.subTextView setContentCompressionResistancePriority: NSLayoutPriorityDefaultHigh forOrientation: NSLayoutConstraintOrientationVertical];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self.subTextView selector: @selector(viewFrameChanged:) name: NSViewFrameDidChangeNotification object: self.subTextView];
}


-(NSAttributedString*) attributedStringFromMessage:(MBMessage *)message {
    NSDictionary* options = @{MBRichMessageViewAttributeName:@YES};
    NSDictionary* attributes = nil;
    
    NSMutableAttributedString* composition = [[NSMutableAttributedString alloc] initWithString: @"" attributes: attributes];
    for (MBMime* node in message.childNodes) {
        NSAttributedString* subComposition = [node asAttributedStringWithOptions: options attributes: attributes];
        if (subComposition) {
            [composition appendAttributedString: subComposition];
        }
    }
    return [composition copy];
}

@end
