//
//  PCEditor+UInterface.h
//  ProjectCenter
//
//  Created by Philippe C.D. Robert on Wed Nov 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "PCEditor.h"

@interface PCEditor (UInterface)

- (void)_initUI;
- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr;

@end
