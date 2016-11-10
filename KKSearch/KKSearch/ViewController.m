//
//  ViewController.m
//  KKSearch
//
//  Created by 宇航 on 16/11/10.
//  Copyright © 2016年 KH. All rights reserved.
//

#import "ViewController.h"
#import "KKSearchExampleVC.h"
#import "PYSearchViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"KKSearch");
    NSLog(@"%d",self.navigationController.navigationBar.translucent);//==1
    UIButton * searchButton = [[UIButton alloc]init];
    searchButton.frame = CGRectMake(100, 120, 50, 30);
    [searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    [searchButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [searchButton addTarget:self action:@selector(DidClickSearchButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];

}

- (void)DidClickSearchButton{
 
    PYSearchViewController * pys = [PYSearchViewController searchViewControllerWithHotSearches:@[@"医生",@"患者",@"科室",@"机构"]searchBarPlaceholder:@"请输入关键字"];
    pys.hotSearchStyle = PYHotSearchStyleRectangleTag;
    pys.searchResultShowMode = PYSearchResultShowModePush;
    UINavigationController * nav = [[UINavigationController alloc]initWithRootViewController:pys];
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
    
}
@end
