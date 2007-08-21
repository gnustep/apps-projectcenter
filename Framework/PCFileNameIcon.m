/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2005 Free Software Foundation

   Authors: Serg Stoyan

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <AppKit/AppKit.h>

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCFileNameIcon.h>
#import <ProjectCenter/PCProjectBrowser.h>

@implementation PCFileNameIcon

- (void)awakeFromNib
{
  filePath = nil;
  [self setImage:[NSImage imageNamed:@"ProjectCenter"]];
  [self 
    registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];

  filePath = nil;
  [self setRefusesFirstResponder:YES];
  [self setEditable:NO];
  [self setImage:[NSImage imageNamed:@"ProjectCenter"]];

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCFileNameIcon: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(fileNameField);
  RELEASE(delegate);

  [super dealloc];
}

- (void)setFileNameField:(NSTextField *)field
{
  fileNameField = RETAIN(field);
}

- (void)setDelegate:(id)object
{
  delegate = object;
}

- (void)updateIcon
{
  if (delegate)
    {
      if ([delegate respondsToSelector:@selector(fileNameIconImage)])
	{
	  [self setImage:[delegate fileNameIconImage]];
	}
      if ([delegate respondsToSelector:@selector(fileNameIconTitle)])
	{
	  [fileNameField setStringValue:[delegate fileNameIconTitle]];
	}
    }
}

// --- Drag and drop

// --- NSDraggingDestination protocol methods
// -- Before the image is released
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray      *paths = [pb propertyListForType:NSFilenamesPboardType];
  unsigned int draggingOp = NSDragOperationNone;

  NSLog(@"Dragging entered");

  if (![paths isKindOfClass:[NSArray class]] || [paths count] == 0)
    {
      return draggingOp;
    }

  if (delegate && 
      [delegate respondsToSelector:@selector(canPerformDraggingOf:)] &&
      [delegate canPerformDraggingOf:paths] == YES)
    {
      draggingOp = NSDragOperationCopy;
    }

  if (draggingOp == NSDragOperationCopy)
    { // TODO: Change icon to icon that shows open state of destination
    }

  return draggingOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}

// -- After the image is released
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  NSLog(@"Prepare for drag operation");
  return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray      *paths = [pb propertyListForType:NSFilenamesPboardType];

  NSLog(@"performDragOperation: %@", paths);

  return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sendera
{
}

@end

