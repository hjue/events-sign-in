//
//  CEMemberList.m
//  EventsSignIn
//
//  Created by hjue on 5/19/14.
//  Copyright (c) 2014 CSDN. All rights reserved.
//

#import "CEMemberList.h"

#define LOGFILE @"used.log"

@implementation CEMemberList

- (NSArray *)memberList{
    NSMutableArray *result = [[NSMutableArray alloc]init];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSLog(@"%@",documentPath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentPath error:nil];
    for (NSString *file in files) {
        if ([file rangeOfString:@".txt"].location == NSNotFound) {
            continue;
        }
        NSString *content = [NSString stringWithContentsOfFile:[documentPath stringByAppendingPathComponent:file] encoding:NSUTF8StringEncoding error:nil];
        NSArray *split = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

        for (NSString *line in split) {
            if (line.length>5) {
                [result addObject: line];
            }
        }
    }
    
    return  [result copy];
    
}


- (NSArray *)usedMemberList{
    
    NSMutableArray *result = [[NSMutableArray alloc]init];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logPath = [documentPath stringByAppendingPathComponent:LOGFILE];
    if (![fileManager fileExistsAtPath:logPath]) {
        return [result copy];
    }
    
    NSString *content = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil];
    NSArray *split = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in split) {
        if (line.length>5) {
            [result addObject: line];
        }
    }
    
    return  [result copy];
}

- (BOOL)appendUsedMemberList:(NSArray *)used
{
    NSMutableArray * usedMemberList = [NSMutableArray arrayWithArray:[self usedMemberList]];
    for (NSString *usedLine in used) {
        NSArray *matches = [usedMemberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF matches[c] %@",usedLine]];
        if ([matches count]==0) {
            [usedMemberList addObject:usedLine];
        }
    }
    NSString *content = [usedMemberList componentsJoinedByString:@"\r\n"];
    NSError * error = nil;
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logPath = [documentPath stringByAppendingPathComponent:LOGFILE];
    BOOL success =   [content writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (success) {
        return YES;
    }else{
        NSLog(@"writeToFile failed with error %@", error);
        return NO;
    }
}

@end
