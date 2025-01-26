/*
  GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
 
  Copyright (C) 2003-2019 Free Software Foundation
 
  Authors: Serg Stoyan
           Riccardo Mottola
 
  This file is part of ProjectCenter.
 
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
  Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#import <ProjectCenter/PCButton.h>
#import <ProjectCenter/PCDefines.h>

@implementation PCButton

// ============================================================================
// ==== Main
// ============================================================================

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self)
    {
      [_cell setGradientType:NSGradientConcaveWeak];
      [_cell setImageDimsWhenDisabled:YES];
      [self setImagePosition:NSImageOnly];
      [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [self setRefusesFirstResponder:YES];
    }
  return self;
}

@end

