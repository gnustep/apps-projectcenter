/* 
 * ProjectComponent.h created by probert on 2002-02-10 09:29:07 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PROJECTCOMPONENT_H
#define _PROJECTCOMPONENT_H

@class PCProject;
@class NSView;

@protocol ProjectComponent <NSObject>

- (id)initWithProject:(PCProject *)aProject;

- (NSView *)componentView;

@end

#endif
