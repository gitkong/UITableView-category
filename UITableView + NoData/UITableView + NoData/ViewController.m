//
//  ViewController.m
//  UITableView + NoData
//
//  Created by clarence on 16/12/5.
//  Copyright © 2016年 gitKong. All rights reserved.
//

#import "ViewController.h"
#import "UITableView+fl_category.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)NSMutableArray *modelArrM;
@property (nonatomic,weak)UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    for (NSInteger index = 0; index < 10; index ++) {
        [self.modelArrM addObject:@" "];
    }
    
    
    self.title = @"gitKong";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"hide Nav & Tab" style:UIBarButtonItemStyleDone target:self action:@selector(hide)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear & reloadData" style:UIBarButtonItemStyleDone target:self action:@selector(reloadModelArrM)];
    
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    // 没数据显示
    // tableView.fl_noData_image = @"https://github.com/fluidicon.png";
    tableView.fl_noData_image = @"http://photo.l99.com/source/11/1330351552722_cxn26e.gif";
    // tableView.fl_noData_image = @"2.gif";
    
    // 没网络显示
    tableView.fl_noNetwork_image = @"1.jpg";
    
    // 点击操作
    __weak typeof(self) weakSelf = self;
    [tableView fl_imageViewClickOperation:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.navigationController.navigationBarHidden = NO;
        strongSelf.tabBarController.tabBar.hidden = NO;
        [strongSelf.modelArrM addObjectsFromArray:@[@" ",@"1",@" "]];
        [strongSelf.tableView reloadData];
        NSLog(@"----");
    }];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
}



- (void)hide{
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    [self.tableView reloadData];
}

- (void)reloadModelArrM{
    [self.modelArrM removeAllObjects];
    [self.tableView reloadData];
}


#pragma mark - Table view data source & delegate
static NSString * resueId = @"cell";

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.modelArrM.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resueId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:resueId];
    }
    cell.textLabel.text = @"gitKong";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    NSLog(@"hello gitKong");
}

- (NSMutableArray *)modelArrM{
    if (_modelArrM == nil) {
        _modelArrM = [NSMutableArray array];
    }
    return _modelArrM;
}


@end
