/* 
 * PCProject+ComponentHandling.m created by probert on 2002-02-10 09:50:56 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#include "PCProject+ComponentHandling.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCProjectWindow.h"
#include "ProjectComponent.h"
#include "PCProjectLauncher.h"
#include "PCEditor.h"

@implementation PCProject (ComponentHandling)

- (void)runSelectedTarget:(id)sender
{
  if (!projectLauncher)
    {
      projectLauncher = [[PCProjectLauncher alloc] initWithProject:self];
    }

  [projectLauncher run:sender];
}

@end

