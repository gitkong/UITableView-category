//
//  UITableView+fl_category.m
//  UITableView + NoData
//
//  Created by clarence on 16/12/5.
//  Copyright © 2016年 gitKong. All rights reserved.
//

#import "UITableView+fl_category.h"
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>
//#import "Reachability.h"
@interface UITableView ()

@property (nonatomic,strong)UIImageView *imageView;

@property (nonatomic,copy)void(^clickOperation)();

@end

@implementation UITableView (fl_category)

static NSString *cache;

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换方法
        cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"fl_cache"];
        BOOL isDir = NO;
        BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:&isDir];
        if (!isExists || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
        }
        // 交换方法
        [self methodSwizzlingWithOriginalSelector:@selector(reloadData) bySwizzledSelector:@selector(fl_reloadData)];
    });
}


+ (void)methodSwizzlingWithOriginalSelector:(SEL)originalSelector bySwizzledSelector:(SEL)swizzledSelector{
    Class class = [self class];
    //原有方法
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    //替换原有方法的新方法
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    //先尝试給源SEL添加IMP，这里是为了避免源SEL没有实现IMP的情况
    BOOL didAddMethod = class_addMethod(class,originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {//添加成功：说明源SEL没有实现IMP，将源SEL的IMP替换到交换SEL的IMP
        class_replaceMethod(class,swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {//添加失败：说明源SEL已经有IMP，直接将两个SEL的IMP交换即可
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static char *static_no_data_key = "static_no_data_key";
static char *static_no_network_key = "static_no_network_key";
static char *static_ImageView_key = "static_ImageView_key";
static char *static_ImageView_operation_key = "static_ImageView_operation_key";

- (void)setFl_noData_image:(NSString *)fl_noData_image{
    NSAssert(fl_noData_image, @"noData_image 不能为空");
    objc_setAssociatedObject(self, &static_no_data_key, fl_noData_image, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
}

- (NSString *)fl_noData_image{
    return objc_getAssociatedObject(self, &static_no_data_key);
}

- (void)setFl_noNetwork_image:(NSString *)fl_noNetwork_image{
    objc_setAssociatedObject(self, &static_no_network_key, fl_noNetwork_image, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
}

- (NSString *)fl_noNetwork_image{
    return objc_getAssociatedObject(self, &static_no_network_key);
}

- (void)setImageView:(UIImageView *)imageView{
    objc_setAssociatedObject(self, &static_ImageView_key, imageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImageView *)imageView{
    UIImageView *imgV = objc_getAssociatedObject(self, &static_ImageView_key);
    if (imgV == nil) {
        // 添加到wrapperView，tableView的y不会下移导航栏的高度，wrapperView会偏移
        UIView *wrapperView = [self valueForKey:@"wrapperView"];
        imgV = [[UIImageView alloc] init];
        imgV.userInteractionEnabled = YES;
        // 添加事件
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickToOperate)];
        [imgV addGestureRecognizer:tap];
        self.imageView = imgV;
        // 布局frame
        [self updataImageViewFrame];
        
        [wrapperView addSubview:imgV];
        [wrapperView bringSubviewToFront:imgV];
    }
    return imgV;
}

- (void)setClickOperation:(void (^)())clickOperation{
    objc_setAssociatedObject(self, &static_ImageView_operation_key, clickOperation, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)())clickOperation{
    return objc_getAssociatedObject(self, &static_ImageView_operation_key);
}


- (void)clickToOperate{
    if (self.clickOperation) {
        self.clickOperation();
    }
}

- (void)updataImageViewFrame{
    // 如果没有导航控制器，那么rect的y值为0，如果有导航控制器，那么y为-64,如果导航控制器hidden那么也会跟着变，不需要额外修改
    Class conecreteValue = NSClassFromString(@"NSConcreteValue");
    id concreteV = [[conecreteValue alloc] init];
    concreteV = [self valueForKey:@"visibleBounds"];
    CGRect rect ;
    [concreteV getValue:&rect];
    
    // 判断是否有tabBar显示
    // 注意：分类中使用[UITabBar appearance] 和 [UINavigationBar appearance] 都不能获取对象，断点po提示<_UIAppearance:0x17025b000> <Customizable class: UITabBar> with invocations (null)>
    UIViewController *currentVc = [self fl_viewController];
    UITabBarController *tabVc = (UITabBarController *)currentVc.tabBarController;
    if (tabVc) {
        self.imageView.frame = CGRectMake(rect.origin.x, 0, rect.size.width, rect.size.height + rect.origin.y - (tabVc.tabBar.hidden ? 0 : tabVc.tabBar.bounds.size.height));
    }
    else{
        self.imageView.frame = CGRectMake(rect.origin.x, 0, rect.size.width, rect.size.height + rect.origin.y);
    }
}

/**
 *  @author gitKong
 *
 *  设置imageView 的 image
 */
- (void)setImage:(NSString *)image{
    
    // 更新imageView 的frame
    [self updataImageViewFrame];
    // 判断沙盒,先把名字/去掉，防止创建多个文件夹
    NSString *imageName = [image stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *path = [cache stringByAppendingPathComponent:imageName];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {
        self.imageView.image = [self getImageWithData:data];
    }
    
    else{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:image]];
        __weak typeof(self) weakSelf = self;
        
        if (data) {// 网络url
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *networkImg = [self getImageWithData:data];
                // 缓存在沙盒中
                [data writeToFile:path atomically:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.imageView.image = networkImg;
                });
            });
            
        }
        else{// 项目中文件
            if ([image rangeOfString:@".gif"].location != NSNotFound) {
                self.imageView.image = [self gifImageNamed:image];
            }
            else{
                self.imageView.image = [UIImage imageNamed:image];
            }
        }
    }
}

#pragma mark 下载图片，如果是gif则计算动画时长
- (UIImage *)getImageWithData:(NSData *)data{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(imageSource);
    if (count <= 1) { //非gif
        CFRelease(imageSource);
        return [[UIImage alloc] initWithData:data];
    } else { //gif图片
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
            if (!image) continue;
            duration += [self durationWithSource:imageSource atIndex:i];
            [images addObject:[UIImage imageWithCGImage:image]];
            CGImageRelease(image);
        }
        if (!duration) duration = 0.1 * count;
        CFRelease(imageSource);
        return [UIImage animatedImageWithImages:images duration:duration];
    }
}

#pragma mark 获取每一帧图片的时长
- (CGFloat)durationWithSource:(CGImageSourceRef)source atIndex:(NSUInteger)index {
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *properties = (__bridge NSDictionary *)propertiesRef;
    NSDictionary *gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) duration = delayTime.floatValue;
    else {
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) duration = delayTime.floatValue;
    }
    CFRelease(propertiesRef);
    return duration;
}

- (UIImage *)gifImageNamed:(NSString *)gifName{
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:gifName ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    if (data) return [self getImageWithData:data];
    
    return [UIImage imageNamed:gifName];
}



- (BOOL)checkNoNetwork{
    BOOL flag = NO;
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    int netType = 0;
    //获取到网络返回码
    for (id child in children) {
        //        NSLog(@"child = %@",NSStringFromClass([child class]));
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            //获取到状态栏,飞行模式和关闭移动网络都拿不到dataNetworkType；1 - 2G; 2 - 3G; 3 - 4G; 5 - WIFI
            netType = [[child valueForKeyPath:@"dataNetworkType"] intValue];
            
            switch (netType) {
                case 0:
                    flag = NO;
                    //无网模式
                    break;
                    
                default:
                    flag = YES;
                    break;
            }
        }
    }
    //    self.imageView.hidden = flag;
    return flag;
}


- (BOOL)checkNoData{
    NSInteger sections = 1;
    NSInteger row = 0;
    BOOL isEmpty = YES;
    if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        sections = [self.dataSource numberOfSectionsInTableView:self];
    }
    for (NSInteger section = 0; section < sections; section++) {
        row = [self.dataSource tableView:self numberOfRowsInSection:section];
        if (row) {
            // 只要有值都不是空
            isEmpty = NO;
        }
        else{
            isEmpty = YES;
        }
    }
    
    //    self.imageView.hidden = !isEmpty;
    return isEmpty;
}

- (void)fl_reloadData{
    
    // 判断网络状态
    if(![self checkNoNetwork]){
        [self setImage:self.fl_noNetwork_image];
        self.imageView.hidden = NO;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else{
        // 检查数据是否为空
        if([self checkNoData]){
            self.imageView.hidden = NO;
            [self setImage:self.fl_noData_image];
            self.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
        else{
            self.imageView.hidden = YES;
            self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
    }
    
    [self fl_reloadData];
}

- (void)fl_imageViewClickOperation:(void(^)())clickOperation{
    self.clickOperation = clickOperation;
}

/**
 *  @author gitKong
 *
 *  找到当前的控制器
 *  摘自我简书的文章：http://www.jianshu.com/p/dcd26e1ab30f
 */
- (UIViewController *)fl_viewController{
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    // modal
    if (vc.presentedViewController) {
        if ([vc.presentedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navVc = (UINavigationController *)vc.presentedViewController;
            vc = navVc.visibleViewController;
        }
        else if ([vc.presentedViewController isKindOfClass:[UITabBarController class]]){
            UITabBarController *tabVc = (UITabBarController *)vc.presentedViewController;
            if ([tabVc.selectedViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navVc = (UINavigationController *)tabVc.selectedViewController;
                return navVc.visibleViewController;
            }
            else{
                return tabVc.selectedViewController;
            }
        }
        else{
            vc = vc.presentedViewController;
        }
    }
    // push
    else{
        if ([vc isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tabVc = (UITabBarController *)vc;
            if ([tabVc.selectedViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navVc = (UINavigationController *)tabVc.selectedViewController;
                return navVc.visibleViewController;
            }
            else{
                return tabVc.selectedViewController;
            }
        }
        else if([vc isKindOfClass:[UINavigationController class]]){
            UINavigationController *navVc = (UINavigationController *)vc;
            vc = navVc.visibleViewController;
        }
    }
    return vc;
}

@end
