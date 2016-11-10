//
//  代码地址: https://github.com/iphone5solo/PYSearch
//  代码地址: http://www.code4app.com/thread-11175-1-1.html
//  Created by CoderKo1o.
//  Copyright © 2016年 iphone5solo. All rights reserved.
//

#import "PYSearchViewController.h"
#import "PYSearchConst.h"
#import "PYSearchSuggestionViewController.h"
#import "UIViewExt.h"

#define PYRectangleTagMaxCol 4 // 矩阵标签时，最多列数
#define PYTextColor PYColor(113, 113, 113)  // 文本字体颜色
#define PYColorPolRandomColor self.colorPol[arc4random_uniform((uint32_t)self.colorPol.count)] // 随机选取颜色池中的颜色

@interface PYSearchViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

/** 头部内容view */
@property (nonatomic, weak) UIView *headerContentView;

/** 搜索历史 */
@property (nonatomic, strong) NSMutableArray *searchHistories;

/** 键盘正在移动 */
@property (nonatomic, assign) BOOL keyboardshowing;
/** 记录键盘高度 */
@property (nonatomic, assign) CGFloat keyboardHeight;

/** 搜索建议（推荐）控制器 */
@property (nonatomic, weak) PYSearchSuggestionViewController *searchSuggestionVC;

/** 热门标签容器 */
@property (nonatomic, weak) UIView *hotSearchTagsContentView;

/** 排名标签(第几名) */
@property (nonatomic, copy) NSArray<UILabel *> *rankTags;
/** 排名内容 */
@property (nonatomic, copy) NSArray<UILabel *> *rankTextLabels;
/** 排名整体标签（包含第几名和内容） */
@property (nonatomic, copy) NSArray<UIView *> *rankViews;

/** 搜索历史标签容器，只有在PYSearchHistoryStyle值为PYSearchHistoryStyleTag才有值 */
@property (nonatomic, weak) UIView *searchHistoryTagsContentView;
/** 搜索历史标签的清空按钮 */
@property (nonatomic, weak) UIButton *emptyButton;

/** 基本搜索TableView(显示历史搜索和搜索记录) */
@property (nonatomic, strong) UITableView *baseSearchTableView;
/** 记录是否点击搜索建议 */
@property (nonatomic, assign) BOOL didClickSuggestionCell;

@end

@implementation PYSearchViewController

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

+ (PYSearchViewController *)searchViewControllerWithHotSearches:(NSArray<NSString *> *)hotSearches searchBarPlaceholder:(NSString *)placeholder
{
    PYSearchViewController *searchVC = [[PYSearchViewController alloc] init];
    searchVC.hotSearches = hotSearches;
    searchVC.searchBar.placeholder = placeholder;
    return searchVC;
}

+ (PYSearchViewController *)searchViewControllerWithHotSearches:(NSArray<NSString *> *)hotSearches searchBarPlaceholder:(NSString *)placeholder didSearchBlock:(PYDidSearchBlock)block
{
    PYSearchViewController *searchVC = [self searchViewControllerWithHotSearches:hotSearches searchBarPlaceholder:placeholder];
    searchVC.didSearchBlock = [block copy];
    return searchVC;
}

#pragma mark - 懒加载
- (UITableView *)baseSearchTableView
{
    if (!_baseSearchTableView) {
        UITableView *baseSearchTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        baseSearchTableView.backgroundColor = PYBackgroundColor;
        baseSearchTableView.delegate = self;
        baseSearchTableView.dataSource = self;
        [self.view addSubview:baseSearchTableView];
        _baseSearchTableView = baseSearchTableView;
    }
    return _baseSearchTableView;
}

- (UITableViewController *)searchResultController
{
    if (!_searchResultController) {
        _searchResultController = [[UITableViewController alloc] init];
        self.searchResultTableView = _searchResultController.tableView;
    }
    return _searchResultController;
}



- (UIView *)searchHistoryTagsContentView
{
    if (!_searchHistoryTagsContentView) {
        UIView *searchHistoryTagsContentView = [[UIView alloc] init];
        searchHistoryTagsContentView.py_width = PYScreenW - PYMargin * 2;
        searchHistoryTagsContentView.py_y = CGRectGetMaxY(self.hotSearchTagsContentView.frame) + PYMargin;
        [self.headerContentView addSubview:searchHistoryTagsContentView];
        _searchHistoryTagsContentView = searchHistoryTagsContentView;
    }
    return _searchHistoryTagsContentView;
}

- (NSMutableArray *)searchHistories
{
    if (!_searchHistories) {
        _searchHistories = [NSKeyedUnarchiver unarchiveObjectWithFile:PYSearchHistoriesPath];
        if (!_searchHistories) {
            _searchHistories = [NSMutableArray array];
        }
    }
    return _searchHistories;
}


/** 视图加载完毕 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

/** 视图将要显示 */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES];
    // 没有热门搜索并且搜索历史为默认PYHotSearchStyleDefault就隐藏
 
}

/** 视图完全显示 */
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 弹出键盘
    [self.searchBar becomeFirstResponder];
}

/** 控制器销毁 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/** 初始化 */
- (void)setup
{
    self.baseSearchTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(cancelDidClick)];
    // 设置搜索结果显示模式
    self.searchResultShowMode = PYSearchResultShowModeDefault;
    // 显示搜索建议
    self.searchSuggestionHidden = NO;
    
    // 创建搜索框
    UIView *titleView = [[UIView alloc] init];
    titleView.py_x = PYMargin * 0.5;
    titleView.py_y = 7;
    titleView.py_width = self.view.py_width - 64 - titleView.py_x * 2;
    titleView.py_height = 30;
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:titleView.bounds];
    searchBar.py_width -= PYMargin * 1.5;
    searchBar.placeholder = @"请输入关键词";
    searchBar.backgroundImage = [UIImage imageNamed:@"PYSearch.bundle/clearImage"];
    searchBar.delegate = self;
    [titleView addSubview:searchBar];
    self.searchBar = searchBar;
    self.navigationItem.titleView = titleView;
    
    // headerView
    UISegmentedControl *seg = [[UISegmentedControl alloc]initWithItems:@[@"医生",@"教师",@"司机",@"设计师"]];
    seg.tintColor = [UIColor purpleColor];
    seg.frame = CGRectMake(8, 20, KScreenWidth-16, 40);
    seg.selectedSegmentIndex = 0;
    [seg  addTarget:self action:@selector(click) forControlEvents:UIControlEventValueChanged];
    UIView * headView = [UIView new];
    [headView addSubview:seg];
    headView.height = CGRectGetMaxY(seg.frame);
    headView.width = KScreenWidth;
    self.baseSearchTableView.tableHeaderView = headView;
//    headView.backgroundColor = [UIColor redColor];
    // 设置底部(清除历史搜索)
//    UIView *footerView = [[UIView alloc] init];
//    footerView.py_width = PYScreenW;
//    UILabel *emptySearchHistoryLabel = [[UILabel alloc] init];
//    emptySearchHistoryLabel.textColor = [UIColor darkGrayColor];
//    emptySearchHistoryLabel.font = [UIFont systemFontOfSize:13];
//    emptySearchHistoryLabel.userInteractionEnabled = YES;
//    emptySearchHistoryLabel.text = @"清空历史搜索";
//    emptySearchHistoryLabel.textAlignment = NSTextAlignmentCenter;
//    emptySearchHistoryLabel.py_height = 30;
//    [emptySearchHistoryLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emptySearchHistoryDidClick)]];
//    emptySearchHistoryLabel.py_width = PYScreenW;
//    [footerView addSubview:emptySearchHistoryLabel];
//    footerView.py_height = 30;
//    self.baseSearchTableView.tableFooterView = footerView;
}

- (void)click
{
    NSLog(@"%s",__func__);
}


/** 点击取消 */
- (void)cancelDidClick
{
    [self.searchBar resignFirstResponder];
    
    // dismiss ViewController
    [self dismissViewControllerAnimated:NO completion:nil];
    
    // 调用代理方法
    if ([self.delegate respondsToSelector:@selector(didClickCancel:)]) {
        [self.delegate didClickCancel:self];
    }
}

/** 键盘显示完成（弹出） */
- (void)keyboardDidShow:(NSNotification *)noti
{
    // 取出键盘高度
    NSDictionary *info = noti.userInfo;
    self.keyboardHeight = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.keyboardshowing = YES;
}

/** 点击清空历史按钮 */
- (void)emptySearchHistoryDidClick
{
    // 移除所有历史搜索
    [self.searchHistories removeAllObjects];
    // 移除数据缓存
    [NSKeyedArchiver archiveRootObject:self.searchHistories toFile:PYSearchHistoriesPath];
    if (self.searchHistoryStyle == PYSearchHistoryStyleCell) {
        // 刷新cell
        [self.baseSearchTableView reloadData];
    } else {
        // 更新
        self.searchHistoryStyle = self.searchHistoryStyle;
    }
    PYSearchLog(@"清空历史记录");
}
/** 点击清除某一个按钮 */
- (void)closeDidClick:(UIButton*)sender{
    
    //获取当前cell
    UITableViewCell *cell = (UITableViewCell*)sender.superview;
    //移除搜索信息
    [self.searchHistories removeObject:cell.textLabel.text];
    //保存搜索信息
    [NSKeyedArchiver archiveRootObject:self.searchHistories toFile:PYSearchHistoryText];
    //刷新
    [self.baseSearchTableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // 回收键盘
    [searchBar resignFirstResponder];
    // 先移除再刷新
    [self.searchHistories removeObject:searchBar.text];
    [self.searchHistories insertObject:searchBar.text atIndex:0];
    // 刷新数据
    if (self.searchHistoryStyle == PYSearchHistoryStyleCell) { // 普通风格Cell
        [self.baseSearchTableView reloadData];
    } else { // 搜索历史为标签
        // 更新
        self.searchHistoryStyle = self.searchHistoryStyle;
    }
    // 保存搜索信息
    [NSKeyedArchiver archiveRootObject:self.searchHistories toFile:PYSearchHistoriesPath];
    // 处理搜索结果
    switch (self.searchResultShowMode) {
        case PYSearchResultShowModePush: // Push
            [self.navigationController pushViewController:self.searchResultController animated:YES];
            break;
        case PYSearchResultShowModeEmbed: // 内嵌
            // 添加搜索结果的视图
            [self.view addSubview:self.searchResultController.tableView];
            [self addChildViewController:self.searchResultController];
            break;
        case PYSearchResultShowModeCustom: // 自定义
            
            break;
        default:
            break;
    }
    
    // 如果代理实现了代理方法则调用代理方法
    if ([self.delegate respondsToSelector:@selector(searchViewController:didSearchWithsearchBar:searchText:)]) {
        [self.delegate searchViewController:self didSearchWithsearchBar:searchBar searchText:searchBar.text];
        return;
    }
    // 如果有block则调用
    if (self.didSearchBlock) self.didSearchBlock(self, searchBar, searchBar.text);
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // 根据输入文本显示建议搜索条件
    self.searchSuggestionVC.view.hidden = self.searchSuggestionHidden || !searchText.length;
    // 放在最上层
    [self.view bringSubviewToFront:self.searchSuggestionVC.view];
    // 如果代理实现了代理方法则调用代理方法
    if ([self.delegate respondsToSelector:@selector(searchViewController:searchTextDidChange:searchText:)]) {
        [self.delegate searchViewController:self searchTextDidChange:searchBar searchText:searchText];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return  1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 没有搜索记录就隐藏
    //self.baseSearchTableView.tableFooterView.hidden = self.searchHistories.count == 0;
    return  self.searchHistoryStyle == PYSearchHistoryStyleCell ? self.searchHistories.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"PYSearchHistoryCellID";
    // 创建cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.textLabel.textColor = PYTextColor;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.backgroundColor = [UIColor clearColor];
        
        // 添加关闭按钮
        UIButton *closetButton = [[UIButton alloc] init];
        // 设置图片容器大小、图片原图居中
        closetButton.py_size = CGSizeMake(cell.py_height, cell.py_height);
        [closetButton setImage:[UIImage imageNamed:@"PYSearch.bundle/close"] forState:UIControlStateNormal];
        UIImageView *closeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PYSearch.bundle/close"]];
        [closetButton addTarget:self action:@selector(closeDidClick:) forControlEvents:UIControlEventTouchUpInside];
        closeView.contentMode = UIViewContentModeCenter;
        cell.accessoryView = closetButton;
        // 添加分割线
        UIImageView *line = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PYSearch.bundle/cell-content-line"]];
        line.py_height = 0.5;
        line.alpha = 0.7;
        line.py_x = PYMargin;
        line.py_y = 43;
        line.py_width = PYScreenW;
        [cell.contentView addSubview:line];
    }
    
    // 设置数据
    cell.imageView.image = PYSearchHistoryImage;
    cell.textLabel.text = self.searchHistories[indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.searchHistories.count && self.searchHistoryStyle == PYSearchHistoryStyleCell ? PYSearchHistoryText : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 35;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectio
{
    UIView * sectionHeader = [UIView new];
    UILabel * history = [UILabel new];
    history.frame = CGRectMake(16, 10, 100, 25);
    history.text = @"最近搜索";
    history.font = [UIFont systemFontOfSize:13];
    [sectionHeader addSubview:history];
    
    // 设置底部(清除历史搜索)
    UILabel *emptySearchHistoryLabel = [[UILabel alloc] init];
    emptySearchHistoryLabel.textColor = [UIColor darkGrayColor];
    emptySearchHistoryLabel.font = [UIFont systemFontOfSize:13];
    emptySearchHistoryLabel.userInteractionEnabled = YES;
    emptySearchHistoryLabel.text = @"清空历史搜索";
    emptySearchHistoryLabel.textAlignment = NSTextAlignmentRight;
    emptySearchHistoryLabel.py_height = 25;
    [emptySearchHistoryLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emptySearchHistoryDidClick)]];
    emptySearchHistoryLabel.py_width = 100;
    emptySearchHistoryLabel.frame = CGRectMake(KScreenWidth-100-16, 10, 100, 25);
    [sectionHeader addSubview:emptySearchHistoryLabel];
    
    return sectionHeader;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 取出选中的cell
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.searchBar.text = cell.textLabel.text;
    [self searchBarSearchButtonClicked:self.searchBar];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 滚动时，回收键盘
    if (self.keyboardshowing) [self.searchBar resignFirstResponder];
}

@end
