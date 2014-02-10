//
//  Event.h
//  MDMCoreData
//
//  Created by xzolian on 2/10/14.
//  Copyright (c) 2014 Matthew Morey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * timeStamp;

@end
