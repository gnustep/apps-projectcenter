/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

   Author: Philippe C.D. Robert
           Serg Stoyan

   Description: Loads all PC bundles from all the paths that are stored 
                in the defaults under the key BundlePaths.
 
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

#ifndef _PCBUNDLELOADER_H
#define _PCBUNDLELOADER_H

#include <AppKit/AppKit.h>

@interface PCBundleLoader : NSObject
{
    id 			delegate; // The PCAppController!

    NSMutableArray	*loadedBundles;
}

//----------------------------------------------------------------------------
// Init and free methods
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

// Load all bundles found in the BundlePaths
- (void)loadBundles;
- (void)loadBundlesAtPath: (NSString *)path;

// Returns all loaded ProjectCenter bundles.
- (NSArray *)loadedBundles;

@end

@interface NSObject (BundleLoaderDelegates)

- (void)bundleLoader:(id)sender didLoadBundle:(NSBundle *)aBundle;

@end

#endif
