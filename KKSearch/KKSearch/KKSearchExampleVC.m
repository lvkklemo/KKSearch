//
//  KKSearchEacmpleVC.m
//  KKSearch
//
//  Created by 宇航 on 16/11/10.
//  Copyright © 2016年 KH. All rights reserved.
//

#import "KKSearchExampleVC.h"

@interface KKSearchExampleVC ()

@end

@implementation KKSearchExampleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%d",self.navigationController.navigationBar.translucent);//==1
    self.view.backgroundColor =[UIColor whiteColor];
}


@end
