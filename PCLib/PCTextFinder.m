/* 
 * PCTextFinder.m created by probert on 2002-02-03 13:22:59 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

/*
 * This code is heavily based on Ali Ozers TextFinder. All credits belong
 * to Ali!
 *
 */

#import "PCTextFinder.h"
#import "PCDefines.h"

#define Forward YES
#define Backward NO

#define ReplaceAllScopeEntireFile 42
#define ReplaceAllScopeSelection 43

@interface NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string 
        selectedRange:(NSRange)selectedRange 
	      options:(unsigned)options 
	         wrap:(BOOL)wrap;

@end

@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string 
        selectedRange:(NSRange)selectedRange 
	      options:(unsigned)options 
	         wrap:(BOOL)wrap
{
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) 
    {
        searchRange.location = NSMaxRange(selectedRange);
        searchRange.length = length - searchRange.location;
        range = [self rangeOfString:string options:options range:searchRange];

        if ((range.length == 0) && wrap) 
	{
            searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range=[self rangeOfString:string options:options range:searchRange];
        }
    } 
    else 
    {
        searchRange.location = 0;
        searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];

        if ((range.length == 0) && wrap) 
	{
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range=[self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}

@end

@interface PCTextFinder (CreateUI)

- (void)_initUI;

@end

@implementation PCTextFinder (CreateUI)

- (void)_initUI
{
    int mask = (NSTitledWindowMask | NSClosableWindowMask);
    NSRect rect = NSMakeRect( 100, 100, 440, 184 );
    NSTextField *textField;
    NSBox *box;
    NSButtonCell *cell;
    NSMatrix *borderMatrix;

    panel = [[NSPanel alloc] initWithContentRect:rect
                                       styleMask:mask
                                         backing:NSBackingStoreBuffered
                                           defer:YES];
    [panel setTitle: @"Find Panel"];
    [panel setReleasedWhenClosed: NO]; 

    // Find textfield
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,148,88,21)];
    [textField setAlignment: NSRightTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Find:"];
    [[panel contentView] addSubview:textField];
    RELEASE(textField);

    rect = NSMakeRect(104,148,328 ,21);
    findTextField = [[NSTextField alloc] initWithFrame:rect];
    [findTextField setAlignment: NSLeftTextAlignment];
    [findTextField setBordered: NO];
    [findTextField setEditable: YES];
    [findTextField setBezeled: YES];
    [findTextField setDrawsBackground: YES];
    [findTextField setStringValue:@""];
    [findTextField setDelegate:self];
    [findTextField setTarget:self];
    [findTextField setAction:@selector(setHost:)];
    [[panel contentView] addSubview:findTextField];
    RELEASE(findTextField);

    [panel makeFirstResponder:findTextField]; 

    // Replace field
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,120,88,21)];
    [textField setAlignment: NSRightTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Replace with:"];
    [[panel contentView] addSubview:textField];
    RELEASE(textField);

    rect = NSMakeRect(104,120,328 ,21);
    replaceTextField = [[NSTextField alloc] initWithFrame:rect];
    [replaceTextField setAlignment: NSLeftTextAlignment];
    [replaceTextField setBordered: NO];
    [replaceTextField setEditable: YES];
    [replaceTextField setBezeled: YES];
    [replaceTextField setDrawsBackground: YES];
    [replaceTextField setStringValue:@""];
    [replaceTextField setDelegate:self];
    [replaceTextField setTarget:self];
    [replaceTextField setAction:@selector(setHost:)];
    [[panel contentView] addSubview:replaceTextField];
    RELEASE(replaceTextField);

    [findTextField setNextResponder:replaceTextField];

    // Options
    rect = NSMakeRect(104,40,144 ,80);
    box = [[NSBox alloc] initWithFrame:rect];
    [box setTitle:@"Replace All Scope"];
    [[panel contentView] addSubview:box];
    RELEASE(box);

    cell = [[NSButtonCell alloc] init];
    [cell setButtonType: NSRadioButton];
    [cell setBordered: NO];
    [cell setImagePosition: NSImageLeft]; 

    rect = NSMakeRect(16,8,112 ,48);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSRadioModeMatrix
                                         prototype: cell
                                      numberOfRows: 2
                                   numberOfColumns: 1];   

    [borderMatrix setIntercellSpacing: NSMakeSize (0, 4) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAutosizesCells: NO];

    cell = [borderMatrix cellAtRow: 0 column: 0];
    [cell setTitle: @"Entire File"];
    [cell setTag:0];
    [cell setAction: @selector(setReplaceAllScope:)];

    cell = [borderMatrix cellAtRow: 1 column: 0];
    [cell setTitle: @"Selection"];
    [cell setTag:1];
    [cell setAction: @selector(setReplaceAllScope:)];

    [borderMatrix sizeToFit];
    [box addSubview:borderMatrix];
    RELEASE(borderMatrix);

    rect = NSMakeRect(252,40,180 ,80);
    box = [[NSBox alloc] initWithFrame:rect];
    [box setTitle:@"Find Options"];
    [[panel contentView] addSubview:box];
    RELEASE(box);

    cell = [[NSButtonCell alloc] init];
    [cell setButtonType: NSSwitchButton];
    [cell setBordered: NO];
    [cell setImagePosition: NSImageLeft]; 

    rect = NSMakeRect(16,8,140 ,48);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSHighlightModeMatrix
                                         prototype: cell
                                      numberOfRows: 2
                                   numberOfColumns: 1];   

    [borderMatrix setIntercellSpacing: NSMakeSize (0, 4) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAutosizesCells: NO];

    ignoreCaseButton = [borderMatrix cellAtRow: 0 column: 0];
    [ignoreCaseButton setTitle: @"Ignore Case"];
    [ignoreCaseButton setState: YES];
    [ignoreCaseButton setAction: @selector(setIgnoreCase:)];

    regexpButton = [borderMatrix cellAtRow: 1 column: 0];
    [regexpButton setTitle: @"Regular Expression"];
    [regexpButton setState: NO];
    //[regexpButton setAction: @selector(setIsRegExp:)];

    [borderMatrix sizeToFit];
    [box addSubview:borderMatrix];
    RELEASE(borderMatrix);

    cell = [[NSButtonCell alloc] init];
    [cell setImagePosition: NSNoImage]; 

    rect = NSMakeRect(8,8,412,24);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSHighlightModeMatrix
                                         prototype: cell
                                      numberOfRows: 1
                                   numberOfColumns: 4];   

    [borderMatrix setIntercellSpacing: NSMakeSize (4, 0) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAction: @selector(buttonPressed:)];
    [borderMatrix setAutosizesCells: NO];
    [replaceTextField setNextResponder:borderMatrix];

    cell = [borderMatrix cellAtRow:0 column:0];
    [cell setTitle: @"Replace All"];
    [cell setTag:0];

    cell = [borderMatrix cellAtRow:0 column:1];
    [cell setTitle: @"Replace"];
    [cell setTag:1];

    cell = [borderMatrix cellAtRow:0 column:2];
    [cell setTitle: @"Previous"];
    [cell setTag:2];

    cell = [borderMatrix cellAtRow:0 column:3];
    [cell setTitle: @"Next"];
    [cell setTag:3];

    [[panel contentView] addSubview:borderMatrix];
    RELEASE(borderMatrix);

    rect = NSMakeRect(16,64,80,24);
    statusField = [[NSTextField alloc] initWithFrame:rect];
    [statusField setAlignment: NSLeftTextAlignment];
    [statusField setBordered: NO];
    [statusField setEditable: NO];
    [statusField setBezeled: NO];
    [statusField setDrawsBackground: NO];
    [statusField setStringValue:@""];
    [statusField setDelegate:self];
    [[panel contentView] addSubview:statusField];
    RELEASE(statusField);

    [panel setDelegate: self];
    [panel center];
}

@end

@implementation PCTextFinder

static PCTextFinder *_finder = nil;

+ (PCTextFinder*)sharedFinder
{
    if( _finder == nil )
    {
        _finder = [[PCTextFinder alloc] init];
    }

    return _finder;
}

- (id)init
{
    if((self = [super init]))
    {
	shouldReplaceAll = YES;
        shouldIgnoreCase = YES;

        [self setFindString:@""];
	[self loadFindStringFromPasteboard];
    }
    return self;
}

- (void)dealloc
{
    if( panel != nil )
    {
        RELEASE(panel);
    }

    [super dealloc];
}

- (NSPanel *)findPanel
{
    if( panel == nil )
    {
        [self _initUI];
    }

    return panel;
}

- (void)showFindPanel:(id)sender
{
    if( panel == nil )
    {
        [self _initUI];
    }

    [panel orderFront:self];
}

- (void)buttonPressed:(id)sender
{
    switch([[sender selectedCell] tag] )
    {
        case 0:
	    [self replaceAll:sender];
	    break;
        case 1:
	    [self replace:sender];
	    break;
        case 2:
	    [self findPrevious:sender];
	    break;
        case 3:
	    [self findNext:sender];
	    break;
    }
}

- (void)setReplaceAllScope:(id)sender
{
    switch([[sender selectedCell] tag] )
    {
        case 0:
	    shouldReplaceAll = YES;
	    break;
        case 1:
	    shouldReplaceAll = NO;
	    break;
    }
}

- (void)setIgnoreCase:(id)sender
{
    if( [ignoreCaseButton state] )
    {
        shouldIgnoreCase = YES;
    }
    else
    {
        shouldIgnoreCase = NO;
    }
}

- (BOOL)find:(BOOL)direction
{
    NSTextView *text = [self textObjectToSearchIn];
    lastFindWasSuccessful = NO;

    if (text) 
    {
        NSString *textContents = [text string];
        unsigned textLength;

        if (textContents && (textLength = [textContents length])) 
        {
            NSRange range;
            unsigned options = 0;

            if (direction == Backward) options |= NSBackwardsSearch;
            if (shouldIgnoreCase) options |= NSCaseInsensitiveSearch;

            range = [textContents findString:[self findString] 
                               selectedRange:[text selectedRange] 
                                     options:options 
                                        wrap:YES];

            if (range.length) 
            {
                [text setSelectedRange:range];
                [text scrollRangeToVisible:range];
                lastFindWasSuccessful = YES;
            }
        }
    }

    if (!lastFindWasSuccessful) 
    {
        NSBeep();

        [statusField setStringValue:@"Not found"];
    } 
    else 
    {
        [statusField setStringValue:@""];
    }

    return lastFindWasSuccessful;
}

- (NSTextView *)textObjectToSearchIn
{
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (NSString *)findString
{
    return findString;
}

- (void)setFindString:(NSString *)string
{
    if ([string isEqualToString:findString]) return;

    AUTORELEASE(findString);
    findString = [string copyWithZone:[self zone]];

    if (findTextField) 
    {
        [findTextField setStringValue:string];
        [findTextField selectText:nil];
    }
    findStringChangedSinceLastPasteboardUpdate = YES;
}
    
- (void)loadFindStringFromPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

    if ([[pasteboard types] containsObject:NSStringPboardType]) 
    {
        NSString *string = [pasteboard stringForType:NSStringPboardType];

        if (string && [string length]) 
	{
            [self setFindString:string];
            findStringChangedSinceLastPasteboardUpdate = NO;
        }
    }
}

- (void)loadFindStringToPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

    if (findStringChangedSinceLastPasteboardUpdate) 
    {
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] 
	                   owner:nil];
        [pasteboard setString:[self findString] forType:NSStringPboardType];

        findStringChangedSinceLastPasteboardUpdate = NO;
    }
}


- (void)findNext:(id)sender
{
    if (findTextField) 
    {
        [self setFindString:[findTextField stringValue]];        
    }

    [self find:Forward];
}

- (void)findPrevious:(id)sender
{
    if (findTextField) 
    {
        [self setFindString:[findTextField stringValue]];        
    }

    [self find:Backward];
}

- (void)findNextAndOrderFindPanelOut:(id)sender;
{
}

- (void)replace:(id)sender
{
    NSTextView *text = [self textObjectToSearchIn];

    if (!text) 
    {
        NSBeep();
	[statusField setStringValue:@"No text!"];
    } 
    else 
    {
        [[text textStorage] replaceCharactersInRange:[text selectedRange] 
                                          withString:[replaceTextField stringValue]];
        [text didChangeText];
    }

    [statusField setStringValue:@""];
}

- (void)replaceAll:(id)sender;
{
    NSTextView *text = [self textObjectToSearchIn];

    if (!text) 
    {
        NSBeep();
    } 
    else 
    {
        NSTextStorage *textStorage = [text textStorage];
        NSString *textContents = [text string];
        NSString *replaceString = [replaceTextField stringValue];
        unsigned replaced = 0;
        NSRange replaceRange = shouldReplaceAll 
	                       ? NSMakeRange(0, [textStorage length]) 
			       : [text selectedRange];
        unsigned options = NSBackwardsSearch |
	                   ( shouldIgnoreCase ? NSCaseInsensitiveSearch : 0);

        if (findTextField) [self setFindString:[findTextField stringValue]];

        while (1) 
	{
            NSRange foundRange = [textContents rangeOfString:[self findString] 
	                                             options:options 
						       range:replaceRange];

            if (foundRange.length == 0) 
	    {
	        break;
	    }

            if ([text shouldChangeTextInRange:foundRange replacementString:replaceString]) 
	    {
                if (replaced == 0) 
		{
		    [textStorage beginEditing];
		}

                replaced++;
                [textStorage replaceCharactersInRange:foundRange 
		                           withString:replaceString];
                replaceRange.length = foundRange.location - replaceRange.location;
            }
        }

	// There was at least one replacement
        if (replaced > 0) 
	{     
            [textStorage endEditing];   
            [text didChangeText];       

            [statusField setStringValue:[NSString stringWithFormat:@"%d replaced", replaced]];
        } 
	else 
	{        
            NSBeep();
            [statusField setStringValue:@"Not found"];
        }
    }
}

@end
