/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#include <AppKit/AppKit.h>

#include <ProjectCenter/PCDefines.h>
#include"PCAppController.h"

void createMenu();

int main(int argc, const char **argv) 
{
#ifdef GNUSTEP_BASE_VERSION
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  PCAppController   *controller;

  [NSApplication sharedApplication];

  createMenu();

  controller = [[PCAppController alloc] init];
  [NSApp setDelegate:controller];

  RELEASE(pool);
#endif

  return NSApplicationMain (argc, argv);
}

void 
createMenu()
{
  NSMenu *menu;
  NSMenu *info;
  
  NSMenu *project;
  NSMenu *subprojects;
  
  NSMenu *file;
  NSMenu *file_view;
  
  NSMenu *edit;
  NSMenu *edit_find;
  NSMenu *edit_undo;
  NSMenu *edit_indent;
  
  NSMenu *format;
  NSMenu *format_font;
  NSMenu *format_text;
  
  NSMenu *tools;
  NSMenu *tools_build;
  NSMenu *tools_find;
  NSMenu *tools_files;
  NSMenu *tools_launcher;
  NSMenu *tools_indexer;

  NSMenu *windows;
  NSMenu *services;

  SEL action = @selector(method:);

  menu = [[NSMenu alloc] initWithTitle: @"PC"];

  /*
   * The main menu
   */

  [menu addItemWithTitle:@"Info" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Project" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"File" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Edit" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Format" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Tools" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Windows" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Print..." action:action keyEquivalent:@"p"];
  [menu addItemWithTitle:@"Services" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Hide" action:@selector(hide:) keyEquivalent:@"h"];
  [menu addItemWithTitle:@"Quit" action:@selector(terminate:)
                          keyEquivalent:@"q"];

  /*
   * Info submenu
   */

  info = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:info forItem:[menu itemWithTitle:@"Info"]];
  [info addItemWithTitle:@"Info Panel..." 
	          action:@selector(showInfoPanel:)
	   keyEquivalent:@""];
  [info addItemWithTitle:@"Preferences..." 
	          action:@selector(showPrefWindow:)
	   keyEquivalent:@""];
  [info addItemWithTitle:@"Help" 
	          action:action
	   keyEquivalent:@"?"];

  /*
   * Project submenu
   */

  project = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:project forItem:[menu itemWithTitle:@"Project"]];
  [project addItemWithTitle:@"Open..." 
	             action:@selector(openProject:)
	      keyEquivalent:@"O"];
  [project addItemWithTitle:@"New..."
	             action:@selector(newProject:)
	      keyEquivalent:@"N"];
  [project addItemWithTitle:@"Save"
	             action:@selector(saveProject:) 
	      keyEquivalent:@"S"];
  [project addItemWithTitle:@"Save As..."
	             action:@selector(saveProjectAs:)
	      keyEquivalent:@""];
  [project addItemWithTitle:@"Add Files..."
	             action:@selector(addFile:)
	      keyEquivalent:@"A"];
  [project addItemWithTitle:@"Save Files..."
	             action:@selector(saveFiles:)
	      keyEquivalent:@"Q"];
  [project addItemWithTitle:@"Remove Files..."
	             action:@selector(removeFile:)
	      keyEquivalent:@"r"];
  [project addItemWithTitle:@"Subprojects"
	             action:action
	      keyEquivalent:@""];
  [project addItemWithTitle:@"Close"
	             action:@selector(closeProject:)
	      keyEquivalent:@""];

  subprojects = [[[NSMenu alloc] init] autorelease];
  [project setSubmenu:subprojects
              forItem:[project itemWithTitle:@"Subprojects"]];
  [subprojects addItemWithTitle:@"New..."
	                 action:@selector(newSubproject:)
                  keyEquivalent:@""];
  [subprojects addItemWithTitle:@"Add..."
	                 action:@selector(addSubproject:)
                  keyEquivalent:@""];
  [subprojects addItemWithTitle:@"Remove..."
	                 action:@selector(removeSubproject:)
                  keyEquivalent:@""];

  /*
   * File submenu
   */
  file = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:file forItem:[menu itemWithTitle:@"File"]];
  [file addItemWithTitle:@"Open..."
                  action:@selector(openFile:)
	   keyEquivalent:@"o"];
  [file addItemWithTitle:@"New in Project"
                  action:@selector(newFile:)
	   keyEquivalent:@"n"];
  [file addItemWithTitle:@"Save"
                  action:@selector(saveFile:)
	   keyEquivalent:@"s"];
  [file addItemWithTitle:@"Save As..."
                  action:@selector(saveFile:)
	   keyEquivalent:@""];
  [file addItemWithTitle:@"Save To..."
                  action:action
	   keyEquivalent:@""];
  [file addItemWithTitle:@"Revert to Saved"
                  action:@selector(revertFile:)
	   keyEquivalent:@"u"];
  [file addItemWithTitle:@"Close"
                  action:action
	   keyEquivalent:@"W"];
  [file addItemWithTitle:@"View"
                  action:action
	   keyEquivalent:@""];
  [file addItemWithTitle:@"Open Quickly..."
                  action:action
	   keyEquivalent:@"D"];
  [file addItemWithTitle:@"Rename"
                  action:@selector(renameFile:)
	   keyEquivalent:@""];
  [file addItemWithTitle:@"New Untitled"
                  action:action
	   keyEquivalent:@""];
		  
  file_view = [[[NSMenu alloc] init] autorelease];
  [file setSubmenu:file_view
           forItem:[file itemWithTitle:@"View"]];
  [file_view addItemWithTitle:@"Split"
                       action:action
		keyEquivalent:@"2"];
  [file_view addItemWithTitle:@"Maximize"
                       action:action
		keyEquivalent:@"1"];
  [file_view addItemWithTitle:@"Tear Off"
                       action:action
		keyEquivalent:@"T"];

  /*
   * Edit submenu
   */

  edit = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:@"Edit"]];
  [edit addItemWithTitle:@"Cut" 
                  action:@selector(cut:)
	   keyEquivalent:@"x"];
  [edit addItemWithTitle:@"Copy" 
                  action:@selector(copy:)
	   keyEquivalent:@"c"];
  [edit addItemWithTitle:@"Paste" 
                  action:@selector(paste:)
	   keyEquivalent:@"v"];
  [edit addItemWithTitle:@"Delete" 
                  action:@selector(delete:)
	   keyEquivalent:@""];
  [edit addItemWithTitle:@"Select All" 
                  action:@selector(selectAll:)
	   keyEquivalent:@"a"];
  [edit addItemWithTitle:@"Find" 
                  action:action
	   keyEquivalent:@""];
  [edit addItemWithTitle:@"Undo" 
                  action:action
	   keyEquivalent:@""];
  [edit addItemWithTitle:@"Indentation" 
                  action:action
	   keyEquivalent:@""];
  [edit addItemWithTitle:@"Spelling..." 
                  action:action
	   keyEquivalent:@""];
  [edit addItemWithTitle:@"Check Spelling" 
                  action:action
	   keyEquivalent:@";"];

  // Find
  edit_find = [[[NSMenu alloc] init] autorelease];
  [edit setSubmenu:edit_find
           forItem:[edit itemWithTitle:@"Find"]];
  [edit_find addItemWithTitle:@"Find Panel..." 
                       action:@selector(showFindPanel:) 
		keyEquivalent:@"f"];
  [edit_find addItemWithTitle:@"Find Next" 
                       action:@selector(findNext:)
		keyEquivalent:@"g"];
  [edit_find addItemWithTitle:@"Find Previous" 
                       action:@selector(findPrevious:)
		keyEquivalent:@"d"];
  [edit_find addItemWithTitle:@"Enter Selection" 
                       action:action
		keyEquivalent:@"e"];
  [edit_find addItemWithTitle:@"Jump to Selection" 
                       action:action
		keyEquivalent:@"j"];
  [edit_find addItemWithTitle:@"Line Number..." 
                       action:action
		keyEquivalent:@"I"];
  [edit_find addItemWithTitle:@"Man Page" 
                       action:action
		keyEquivalent:@"M"];

  // Undo
  edit_undo = [[[NSMenu alloc] init] autorelease];
  [edit setSubmenu:edit_undo
           forItem:[edit itemWithTitle:@"Undo"]];
  [edit_undo addItemWithTitle:@"Undo" 
                       action:action
		keyEquivalent:@"z"];
  [edit_undo addItemWithTitle:@"Redo" 
                       action:action
		keyEquivalent:@"Z"];
  [edit_undo addItemWithTitle:@"Undo Region" 
                       action:action
		keyEquivalent:@""];

  // Indentation
  edit_indent = [[[NSMenu alloc] init] autorelease];
  [edit setSubmenu:edit_indent
           forItem:[edit itemWithTitle:@"Indentation"]];
  [edit_indent addItemWithTitle:@"Indent" 
                         action:action
		  keyEquivalent:@"i"];
  [edit_indent addItemWithTitle:@"Shift Left" 
                         action:action
		  keyEquivalent:@"["];
  [edit_indent addItemWithTitle:@"Shift Right" 
                         action:action
		  keyEquivalent:@"]"];
  [edit_indent addItemWithTitle:@"Compress Whitesapce" 
                         action:action
		  keyEquivalent:@"{"];
  [edit_indent addItemWithTitle:@"Expand Message Expression" 
                         action:action
		  keyEquivalent:@"}"];

  /*
   * Format submenu
   */
  format = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:format 
           forItem:[menu itemWithTitle:@"Format"]];
  [format addItemWithTitle:@"Font" 
	            action:action
	     keyEquivalent:@""];
  [format addItemWithTitle:@"Text" 
	            action:action
	     keyEquivalent:@""];
  [format addItemWithTitle:@"Make Rich Text" 
	            action:action
	     keyEquivalent:@"R"];
  [format addItemWithTitle:@"Show All Characters" 
	            action:action
	     keyEquivalent:@""];
  [format addItemWithTitle:@"Page Layout..." 
	            action:action
	     keyEquivalent:@"P"];

  // Font
  [format setSubmenu:[[NSFontManager sharedFontManager] fontMenu: YES]
             forItem:[format itemWithTitle:@"Font"]];
  // Text
  format_text = [[[NSMenu alloc] init] autorelease];
  [format setSubmenu:format_text
             forItem:[format itemWithTitle:@"Text"]];
  [format_text addItemWithTitle:@"Align Left" 
	                 action:action
		  keyEquivalent:@""];
  [format_text addItemWithTitle:@"Center" 
	                 action:action
		  keyEquivalent:@""];
  [format_text addItemWithTitle:@"Align Right" 
	                 action:action
		  keyEquivalent:@""];
  [format_text addItemWithTitle:@"Show Ruler" 
	                 action:action
		  keyEquivalent:@""];
  [format_text addItemWithTitle:@"Copy Ruler" 
	                 action:action
		  keyEquivalent:@""];
  [format_text addItemWithTitle:@"Paste Ruler" 
	                 action:action
		  keyEquivalent:@""];
  
  /*
   * Tools submenu
   */

  tools = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:tools forItem:[menu itemWithTitle:@"Tools"]];
  [tools addItemWithTitle:@"Hide Tool Bar"
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Inspector..."
	           action:@selector(showInspector:)
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Loaded Projects..."
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Project Build"
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Project Find"
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Loaded Files"
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Launcher"
	           action:action
	    keyEquivalent:@""];
  [tools addItemWithTitle:@"Indexer"
	           action:action
	    keyEquivalent:@""];

  // Project Build
  tools_build = [[[NSMenu alloc] init] autorelease];
  [tools setSubmenu:tools_build
            forItem:[tools itemWithTitle:@"Project Build"]];
  [tools_build addItemWithTitle:@"Show Panel..." 
                         action:@selector(showBuildPanel:) 
		  keyEquivalent:@""];
  [tools_build addItemWithTitle:@"Build" 
                         action:action
		  keyEquivalent:@"B"];
  [tools_build addItemWithTitle:@"Stop Build" 
                         action:action
		  keyEquivalent:@"/"];
  [tools_build addItemWithTitle:@"Clean" 
                         action:action
		  keyEquivalent:@""];
  [tools_build addItemWithTitle:@"Next Error" 
                         action:action
		  keyEquivalent:@">"];
  [tools_build addItemWithTitle:@"Previous Error" 
                         action:action
		  keyEquivalent:@"<"];

  // Project Find
  tools_find = [[[NSMenu alloc] init] autorelease];
  [tools setSubmenu:tools_find
            forItem:[tools itemWithTitle:@"Project Find"]];
  [tools_find addItemWithTitle:@"Show Panel..." 
                        action:action
		 keyEquivalent:@"F"];
  [tools_find addItemWithTitle:@"Find References" 
                        action:action
		 keyEquivalent:@"0"];
  [tools_find addItemWithTitle:@"Find Definitions" 
                        action:action
		 keyEquivalent:@"9"];
  [tools_find addItemWithTitle:@"Find Text" 
                        action:action
		 keyEquivalent:@"8"];
  [tools_find addItemWithTitle:@"Find Regular Expr" 
                        action:action
		 keyEquivalent:@"7"];
  [tools_find addItemWithTitle:@"Next match" 
                        action:action
		 keyEquivalent:@""];
  [tools_find addItemWithTitle:@"Previuos match" 
                        action:action
		 keyEquivalent:@""];

  // Loaded Files
  tools_files = [[[NSMenu alloc] init] autorelease];
  [tools setSubmenu:tools_files
            forItem:[tools itemWithTitle:@"Loaded Files"]];
  [tools_files addItemWithTitle:@"Show Panel..." 
                         action:action
	 	  keyEquivalent:@"L"];
  [tools_files addItemWithTitle:@"Sort by Time Viewed" 
                         action:action
	 	  keyEquivalent:@""];
  [tools_files addItemWithTitle:@"Sort by Name" 
                         action:action
	 	  keyEquivalent:@""];
  [tools_files addItemWithTitle:@"Next File" 
                         action:action
	 	  keyEquivalent:@"+"];
  [tools_files addItemWithTitle:@"Previuos File" 
                         action:action
	 	  keyEquivalent:@"_"];
  // Launcher
  tools_launcher = [[[NSMenu alloc] init] autorelease];
  [tools setSubmenu:tools_launcher
            forItem:[tools itemWithTitle:@"Launcher"]];
  [tools_launcher addItemWithTitle:@"Show Panel..." 
                           action:@selector(showRunPanel:)
	 	    keyEquivalent:@""];
  [tools_launcher addItemWithTitle:@"Run" 
                           action:@selector(runTarget:)
	 	    keyEquivalent:@""];
  [tools_launcher addItemWithTitle:@"Debug" 
                           action:action
	 	    keyEquivalent:@""];
  // Indexer
  tools_indexer = [[[NSMenu alloc] init] autorelease];
  [tools setSubmenu:tools_indexer
            forItem:[tools itemWithTitle:@"Indexer"]];
  [tools_indexer addItemWithTitle:@"Show Panel..." 
                           action:action
	 	    keyEquivalent:@""];
  [tools_indexer addItemWithTitle:@"Purge Indices" 
                           action:action
	 	    keyEquivalent:@""];
  [tools_indexer addItemWithTitle:@"Index Subproject" 
                           action:action
	 	    keyEquivalent:@"|"];
  [tools_indexer addItemWithTitle:@"Index File" 
                           action:action
	 	    keyEquivalent:@"*"];

  /*
   * Windows submenu
   */

  windows = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:windows forItem:[menu itemWithTitle:@"Windows"]];
  [windows addItemWithTitle:@"Arrange in Front"
		     action:@selector(arrangeInFront:)
	      keyEquivalent:@""];
  [windows addItemWithTitle:@"Miniaturize Window"
		     action:@selector(performMiniaturize:)
	      keyEquivalent:@"m"];
  [windows addItemWithTitle:@"Close Window"
		     action:@selector(performClose:)
	      keyEquivalent:@"w"];

  /*
   * Services submenu
   */

  services = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:services forItem:[menu itemWithTitle:@"Services"]];

  [[NSApplication sharedApplication] setWindowsMenu: windows];
  [[NSApplication sharedApplication] setServicesMenu: services];
  [[NSApplication sharedApplication] setMainMenu:menu];
}

