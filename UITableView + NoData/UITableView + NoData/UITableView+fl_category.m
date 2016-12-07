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
/**
 *  @author gitKong
 *
 *  沙盒路径
 */
static NSString *cache;
/**
 *  @author gitKong
 *
 *  内存缓存
 */
static NSCache *memory_cache;

static BOOL autoCache;
/**
 *  @author gitKong
 *
 *  load是只要类所在文件被引用就会被调用，而initialize是在类或者其子类的第一个方法被调用前调用。所以如果类没有被引用进项目，就不会有load调用；但即使类文件被引用进来，但是没有使用，那么initialize也不会被调用。
 */
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        memory_cache = [[NSCache alloc] init];
        // 最大成本数，超过会自动清空
        memory_cache.totalCostLimit = 10;
        
        autoCache = YES;
        
        // 缓存文件路径
        [self fl_dishCachePath];
        
        // 收到内存警告，要清空缓存
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fl_clearMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        
        // 交换方法
        [self fl_methodSwizzlingWithOriginalSelector:@selector(reloadData) bySwizzledSelector:@selector(fl_reloadData)];
        
    });
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

+ (void)fl_dishCachePath{
    cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"fl_cache"];
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (void)fl_methodSwizzlingWithOriginalSelector:(SEL)originalSelector bySwizzledSelector:(SEL)swizzledSelector{
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class,originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class,swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static char *static_no_data_key = "static_no_data_key";
static char *static_no_network_key = "static_no_network_key";
static char *static_ImageView_key = "static_ImageView_key";
static char *static_ImageView_operation_key = "static_ImageView_operation_key";
static char *static_autoCache_key = "static_autoCache_key";

- (void)setFl_noData_image:(NSString *)fl_noData_image{
    NSAssert(fl_noData_image, @"fl_noData_image 不能为空");
    objc_setAssociatedObject(self, &static_no_data_key, fl_noData_image, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
}

- (NSString *)fl_noData_image{
    return objc_getAssociatedObject(self, &static_no_data_key);
}

- (void)setFl_noNetwork_image:(NSString *)fl_noNetwork_image{
    NSAssert(fl_noNetwork_image, @"fl_noNetwork_image 不能为空");
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

- (void)setFl_autoCache:(BOOL)fl_autoCache{
    objc_setAssociatedObject(self, &static_autoCache_key, @(fl_autoCache), OBJC_ASSOCIATION_ASSIGN);
    autoCache = fl_autoCache;
}

- (BOOL)fl_autoCache{
//    NSNumber *autoCacheNum = objc_getAssociatedObject(self, &static_autoCache_key);
//    return autoCacheNum.boolValue;
    return autoCache;
}

- (void)clickToOperate{
    if (self.clickOperation) {
        self.clickOperation();
    }
}

- (void)updataImageViewFrame{
    // 如果没有导航控制器，那么rect的y = 0，如果有导航控制器，而且UINavigationBar是显示,那么y = -64，如果有导航控制器，但UINavigationBar隐藏,那么y = -20
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
    
    // 判断内存中是否存在
    UIImage *memory_cache_image = [memory_cache objectForKey:image];
    if (memory_cache_image) {
        self.imageView.image = memory_cache_image;
    }
    else{
        // 判断沙盒,先把名字/去掉，防止创建多个文件夹
        NSString *imageName = [image stringByReplacingOccurrencesOfString:@"/" withString:@""];
        NSString *path = [cache stringByAppendingPathComponent:imageName];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            UIImage *dish_cache_image = [self getImageWithData:data];
            self.imageView.image = dish_cache_image;
            if (self.fl_autoCache) {
                // 缓存到内存中
                [memory_cache setObject:dish_cache_image forKey:image];
            }
        }
        
        else{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:image]];
            __weak typeof(self) weakSelf = self;
            
            if (data) {// 网络url
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    UIImage *networkImg = [self getImageWithData:data];
                    
                    if (weakSelf.fl_autoCache) {
                        // 缓存到内存中
                        [memory_cache setObject:networkImg forKey:image];
                        // 缓存在沙盒中
                        [data writeToFile:path atomically:YES];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.imageView.image = networkImg;
                    });
                });
                
            }
            else{// 项目中文件
                if ([image rangeOfString:@".gif"].location != NSNotFound) {
                    UIImage *local_gif_image = [self gifImageNamed:image];
                    self.imageView.image = local_gif_image;
                    if (weakSelf.fl_autoCache) {
                        // 缓存到内存中
                        [memory_cache setObject:local_gif_image forKey:image];
                    }
                }
                else{
                    self.imageView.image = [UIImage imageNamed:image];
                }
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
        if ([self.dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            row = [self.dataSource tableView:self numberOfRowsInSection:section];
            if (row) {
                // 只要有值都不是空
                isEmpty = NO;
            }
            else{
                isEmpty = YES;
            }
        }
    }
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


- (void)fl_clearCache{
    [self fl_clearMemoryCache];
    [self fl_clearDiskCache];
}

- (void)fl_clearMemoryCache{
    // 清空缓存
    [memory_cache removeAllObjects];
}

- (void)fl_clearDiskCache {
    // 清空沙盒
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cache error:NULL];
        
        for (NSString *fileName in contents) {
            [[NSFileManager defaultManager] removeItemAtPath:[cache stringByAppendingPathComponent:fileName] error:nil];
        }
    });
}

- (void)fl_imageViewClickOperation:(void(^)())clickOperation{
    if (clickOperation) {
        self.clickOperation = clickOperation;
    }
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
