//
//  MDMPersistenceControllerViewControllerProtocol.h
//  MDMCoreData
//
//  Created by Matt Glover on 11/05/2014.
//  Copyright (c) 2014 Matthew Morey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MDMPersistenceController;
@protocol MDMPersistenceControllerViewControllerProtocol <NSObject>

- (void)setPersistenceController:(MDMPersistenceController *)persistenceController;

@end
