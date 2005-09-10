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

#include <AppKit/AppKit.h>

#include "PCDefines.h"
#include "PCFileNameIcon.h"
#include "PCProjectBrowser.h"

@implementation PCFileNameIcon

- (void)awakeFromNib
{
  filePath = nil;
  msfText = nil;
  [self setImage:[NSImage imageNamed:@"projectSuitcase"]];

  // Browser
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector (setFileIcon:)
           name:PCBrowserDidSetPathNotification
         object:nil];
}

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];

  filePath = nil;
  msfText = nil;
  [self setRefusesFirstResponder:YES];
  [self setEditable:NO];
  [self setImage:[NSImage imageNamed:@"projectSuitcase"]];

  // Browser
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector (setFileIcon:)
           name:PCBrowserDidSetPathNotification
         object:nil];

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCFileNameIcon: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(fileNameField);

  [super dealloc];
}

- (void)setFileNameField:(NSTextField *)field
{
  fileNameField = RETAIN(field);
}

- (void)setMultipleFilesSelectionText:(NSString *)text
{
  msfText = [text copy];
}

- (void)setFileIcon:(NSNotification *)notification
{
  id       object = [notification object];
  NSString *categoryName = nil;
  NSString *fileName = nil;
  NSString *fileExtension = nil;
  NSString *iconName = nil;
  NSImage  *icon = nil;

  fileName = [object nameOfSelectedFile];
  if (fileName)
    {
      fileExtension = [fileName pathExtension];
    }
  else
    {
      categoryName = [object nameOfSelectedCategory];
    }

/*  PCLogError(self,@"{setFileIcon} file %@ category %@", 
	    fileName, categoryName);*/
  
  // Should be provided by PC*Proj bundles
  if ([[object selectedFiles] count] > 1)
    {
      iconName = [[NSString alloc] initWithString:@"MultiFiles"];
    }
  else if (!categoryName && !fileName) // Nothing selected
    {
      iconName = [[NSString alloc] initWithString:@"projectSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Classes"])
    {
      iconName = [[NSString alloc] initWithString:@"classSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Headers"])
    {
      iconName = [[NSString alloc] initWithString:@"headerSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Other Sources"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Interfaces"])
    {
      iconName = [[NSString alloc] initWithString:@"nibSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Images"])
    {
      iconName = [[NSString alloc] initWithString:@"iconSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Other Resources"])
    {
      iconName = [[NSString alloc] initWithString:@"otherSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Subprojects"])
    {
      iconName = [[NSString alloc] initWithString:@"subprojectSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Documentation"])
    {
      iconName = [[NSString alloc] initWithString:@"helpSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Supporting Files"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Libraries"])
    {
      iconName = [[NSString alloc] initWithString:@"librarySuitcase"];
    }
  else if ([categoryName isEqualToString: @"Non Project Files"])
    {
      iconName = [[NSString alloc] initWithString:@"projectSuitcase"];
    }
    
  if (iconName != nil)
    {
      icon = IMAGE(iconName);
      RELEASE(iconName);
    }
  else //if (fileExtension != nil && ![fileExtension isEqualToString:@""])
    {
      icon = [[NSWorkspace sharedWorkspace] iconForFile:fileName];
    }

  // Set icon 
  if (icon != nil)
    {
      [self setImage:icon];
    }

  // Set title
  if ([[object selectedFiles] count] > 1)
    {
      if (msfText != nil)
	{
	  [fileNameField setStringValue:msfText];
	}
      else
	{
	  [fileNameField setStringValue:
	    [NSString stringWithFormat: 
	    @"%i files", [[object selectedFiles] count]]];
	}
    }
  else if (fileName)
    {
      [fileNameField setStringValue:fileName];
    }
  else if (categoryName)
    {
      [fileNameField setStringValue:categoryName];
    }
  else
    {
//      [fileNameField setStringValue:[project projectName]];
//      [inspector setFileName:nil andIcon:nil];
    }
}

@end

