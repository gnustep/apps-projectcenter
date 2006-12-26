/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2000-2004 Free Software Foundation

   Author: Philippe C.D. Robert
           Serg Stoyan

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

#ifndef _PCBundleManager_h_
#define _PCBundleManager_h_

#include <AppKit/AppKit.h>

@interface PCBundleManager : NSObject
{
  NSMutableDictionary *loadedBundles;
  NSMutableDictionary *bundlesInfo;
}

//----------------------------------------------------------------------------
// Init and free methods
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

- (NSString *)resourcePath;

- (NSDictionary *)infoForBundlesOfType:(NSString *)extension;
- (NSString *)bundlePathWithName:(NSString *)bundleName;
- (NSBundle *)bundleOfType:(NSString *)type forClassName:(NSString *)className;
- (id)objectForClassName:(NSString *)className
	    withProtocol:(Protocol *)proto
	    inBundleType:(NSString *)type;
- (BOOL)loadBundleIfNeededWithName:(NSString *)bundleName;

// Load all bundles found in the BundlePaths
- (void)loadBundlesWithExtension:(NSString *)extension;
- (void)loadBundlesAtPath:(NSString *)path withExtension:(NSString *)extension;
- (BOOL)loadBundleWithFullPath:(NSString *)path;

// Returns all loaded ProjectCenter bundles.
- (NSDictionary *)loadedBundles;

@end

@interface NSObject (BundleManagerDelegates)

- (void)bundleLoader:(id)sender didLoadBundle:(NSBundle *)aBundle;

@end

#endif
