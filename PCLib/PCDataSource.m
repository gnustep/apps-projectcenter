/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

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

   $Id$
*/

#include "PCDataSource.h"

@implementation PCDataSource

- (id)init
{
    if (self = [super init]) {
        data = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}

//===========================================================================================
//==== Data handling
//===========================================================================================

- (void)insertObject:(id)object
{
    if([data indexOfObject:object] == NSNotFound) {
        [data addObject:object];
    }
}

- (void)removeObject:(id)object
{
    int index = [data indexOfObject:object];

    if(index != NSNotFound) {
        [data removeObjectAtIndex:index];
    }
}

- (void)removeObjectAtIndex:(unsigned int)index
{
    if(index < [data count]) {
        [data removeObjectAtIndex:index];
    }
}

- (void)removeAllObjects
{
    [data removeAllObjects];
}

- (NSArray *)allObjects
{
    return data;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    id 	record;

    NSParameterAssert(rowIndex >= 0 && rowIndex < [data count]);

    record = [data objectAtIndex:rowIndex];
    return [record objectForKey:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    id record;

    NSParameterAssert(rowIndex >= 0 && rowIndex < [data count]);

    record = [data objectAtIndex:rowIndex];
    [record setObject:anObject forKey:[aTableColumn identifier]];
}

@end
