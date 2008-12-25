/*
**  PCDebuggerView
**
**  Copyright (c) 2008
**
**  Author: Gregory Casamento <greg_casamento@yahoo.com>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "PCDebuggerView.h"

@implementation PCDebuggerView

-(void)setDebugger:(PCDebugger *)theDebugger
{
  debugger = theDebugger;
}

/**
 * Log string to the view.
 */
- (void) logString:(NSString *)str
	   newLine:(BOOL)newLine
{
  NSRange range;

  // FIXME: Filter this error, until we find a better way to deal with it.
  range = [str rangeOfString: @"[tcsetpgrp failed in terminal_inferior:"];
  if (range.location == NSNotFound)
    {
      [super logString: str newLine: newLine];
    }
}
@end
