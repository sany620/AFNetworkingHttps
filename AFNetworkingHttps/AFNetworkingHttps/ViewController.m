//
//  ViewController.m
//  AFNetworkingHttps
//
//  Created by duanmu on 2020/9/13.
//  Copyright © 2020 duanmu. All rights reserved.
//

#import "ViewController.h"
#import "OnewayHttps.h"
#import "TwowayHttps.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *oneBt;
@property (nonatomic, strong) UIButton *twoBt;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    /*
        .cer和.p12文件暂未放入项目之中，可以根据需要放自己的证书
     */
    self.oneBt = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.oneBt  setFrame:CGRectMake(130, 150, 60, 30)];
    [self.oneBt  setTitle:@"单向" forState:UIControlStateNormal];
    [self.oneBt  addTarget:self action:@selector(clicked1:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.oneBt];

    self.twoBt = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.twoBt  setFrame:CGRectMake(130, 150, 60, 30)];
    [self.twoBt  setTitle:@"单向" forState:UIControlStateNormal];
    [self.twoBt  addTarget:self action:@selector(clicked2:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.twoBt];

}
#pragma mark - 点击事件
- (void)clicked1:(id)sender{
    [OnewayHttps POST:@"" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

    }];
}

- (void)clicked2:(id)sender{
    [TwowayHttps POST:@"" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

    }];
}

@end
