//
//  CSDNReturnGesturnRecognizer.m
//  ProgrammerMagazine
//
//  Created by hjue on 5/8/14.
//  Copyright (c) 2014 CSDN. All rights reserved.
//

#import "CSDNReturnGesturnRecognizer.h"
#import "UIView+FindUIViewController.h"

@implementation CSDNReturnGesturnRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self == nil) {
        return nil;
    }
    [self addTarget:self action:@selector(return:)];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self addTarget:self action:@selector(return:)];
}

- (void)return:(CSDNReturnGesturnRecognizer *)sender
{
    [[self.view firstAvailableUIViewController].navigationController popViewControllerAnimated:YES];
    
}
@end
