//
//  CEMemberList.h
//  EventsSignIn
//
//  Created by hjue on 5/19/14.
//  Copyright (c) 2014 CSDN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CEMemberList : NSObject

- (NSArray *)memberList;

- (NSArray *)usedMemberList;

- (BOOL)appendUsedMemberList:(NSArray *)used ;
@end
