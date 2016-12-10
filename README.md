##一、前言
**1、之前写了一篇 [[UIView 的分类，一句代码显示无数据界面](http://www.jianshu.com/p/7e5c6caf28d4)](http://www.jianshu.com/p/7e5c6caf28d4) ，如果针对 tableView 或者 collectionView 使用起来还是挺麻烦的，简单分析一下吧**
- 优点： 适用范围比较广泛，只要界面是 `UIView 或 其子类` ，都适用

- 缺点：
  -  需要调用者手动管理（创建显示和隐藏），使用起来不方便。
  -  没有针对无网络进行封装，需要调用者在外界自己判断

**2、先来看看本框架达到的效果吧，授人以鱼不如授人以渔！简单功能，本文做了详细分析，开源的更多是封装思想，所以文字比较多，请做好心理准备，但绝对有所收获的**


![无网络显示界面，动态适配](http://upload-images.jianshu.io/upload_images/1085031-20e46e1dca6699ec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/500)


![无数据显示界面，动态适配](http://upload-images.jianshu.io/upload_images/1085031-020d4e87cc6918ac.gif?imageMogr2/auto-orient/strip)



##二、分析思考
- 1、实际项目中使用显示无数据或者无网络界面 ，一般都是 `UITableView` 或者 `UICollectionView` 此时如果使用 [[UIView 的分类](http://www.jianshu.com/p/7e5c6caf28d4)](http://www.jianshu.com/p/7e5c6caf28d4) 相对麻烦很多，如果是给旧项目添加这个功能，修改量就很大了，因为需要手动管理显示和隐藏

- 2、那么如何避免手动管理呢？考虑到 `UITableView` 和 `UICollectionView` 两个都有 `reloadData` 方法，调用一次就会重新重新执行 `dataSource` 数据源方法，实际项目中，我们请求网络拿到列表数据后，都需要调用 `reloadData` ，而恰恰这个时候，为了更好的用户体验，我们也需要处理是否无数据或者无网络，如果没网络，需要显示无网络界面；而无数据就要显示无数据界面，那能不能在 `reloadData`  方法里面就处理了，或许你已经想到了

- 3、对的，用runtime 替换掉tableView 或者 collectionView 的  `reloadData`  方法，然后在替换的方法里面处理好显示界面的逻辑，此时每当执行 `reloadData`  的时候，就自动判断需要显示什么界面，调用者不需要手动管理

- 4、要替换系统的 `reloadData` 方法，有两种方式，分类和继承，原理都一样，本文就使用分类对UITableView 进行分析，当然UICollectionView 也是一样的，思路一样，如果需要，大家可自行实现

- ###5、需要什么样的功能
  -  **（1）参考不同的app，有些 app 显示无数据界面是一张gif 图，当然主流的都是 静态图 ，因此必须支持静图和动图的显示**

  -  **（2）图片数据一般来自本地，但有可能来自网络（后台可以随时更换显示的无数据图，更新维护相对方便），因此必须要支持网络url下载，当然，为了更好的用户体验，网络图片下载后都需要缓存起来，下次就不需要再请求网络，而且，本地的gif也需要缓存到内存中，为了加快读取速度，可以参考SDWebImage，内存和沙盒都缓存起来，先从内存中获取，没有再从沙盒中获取，再没有才请求网络；既然有缓存，肯定也需要清空缓存**

  - ** （3）考虑到此时可能会显示或者隐藏 `UINavigationBar` 或 `UITabBar` ，那么这个无数据或无网络界面也需要动态更新布局，填充界面，不能留空白**

  -  **（4）当然还需要处理点击事件，考虑到分类拓展性不强，因此默认是整个界面点击，如果你是用继承实现，这就好办，还可以提供自定义界面（custom view）等等，本文就不作分析了**

##三、API 设计
>1、是否开启缓存，默认开启，开启后，会缓存到沙盒 以及 内存，如果是本地gif图片，也会缓存到内存

```
/**
 *  @author gitKong
 *
 *  是否开启自动缓存，此时会缓存到沙盒 和 内存中，默认开启
 */
@property (nonatomic,assign)BOOL fl_autoCache;
```

>2、没有数据显示的图片，不能为nil（内部有断言），可以传入本地图片名 或者 网络URL （包括gif，如果本地gif 图，需要加上后缀）

```
/**
 *  @author gitKong
 *
 *  没有数据显示的图片,不能为nil
 *
 *  可传入 本地图片名 或者 网络URL （包括gif）
 */
@property (nonatomic,copy)NSString *fl_noData_image;
```

>3、没有网络显示的图片，不能为nil（内部有断言），可以传入本地图片名 或者 网络URL （包括gif，如果本地gif 图，需要加上后缀）

```
/**
 *  @author gitKong
 *
 *  没有网络显示的图片,不能为nil
 *
 *  可传入 本地图片名 或者 网络URL （包括gif）
 */
@property (nonatomic,copy)NSString *fl_noNetwork_image;
```

>4、没有网络或者没有数据显示界面的点击事件，默认是整个界面的点击响应。如果自定义需求比较大，建议使用继承实现。

```
/**
 *  @author gitKong
 *
 *  没有网络或者没有数据显示界面的点击事件
 */
- (void)fl_imageViewClickOperation:(void(^)())clickOperation;
```

>5、清空缓存，包括沙盒 和 内存中的都会清空，如果需要单独清空，可以从 实现文件 中开放出来

```
/**
 *  @author gitKong
 *
 *  清空缓存(包括沙盒和内存)
 */
- (void)fl_clearCache;
```

##四、关键代码分析 

> 1、**Swizzling方法替换**，在load 方法（load是只要类所在文件被引用就会被调用）中实现，如果方法存在那么直接替换方法，如果不存在则交换方法实现，替换tableView的 `reloadData` 方法，内部处理是否有网络或者有数据显示的界面

```
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
```

> 2、**判断网络状态**，考虑到如果使用 `Reachability` 需要导入文件，有一定的耦合性，不方便移植，因此本框架是通过获取状态栏的信息来判断，通过 runtime && KVC 就很容易获取状态栏的信息（runtime 可以知道 `UIStatusBar` 的所有属性信息，KVC 进行属性操作），经测试发现，飞行模式和关闭移动网络都拿不到 `dataNetworkType` 属性信息，1 - 2G; 2 - 3G; 3 - 4G; 5 - WIFI

```
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
```

> 3、**判断是否有数据** 直接通过 `dataSource` 获取对应的 `section` 和 `row` 进行判断，只要 `row` 不为空，那么就证明有数据

```
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
```

> 4、**判断NavigationBar和TabBar 显示隐藏**，更新界面的布局，填充不留空白
-  判断NavigationBar （提供三种方案）
  -  通过 `runtime` 发现 `UITableView` 有 一个隐藏属性 `visibleBounds` ，直译过来就是可视区域，通过实测，如果没有导航控制器，那么 `visibleBounds` 的`y = 0`，如果有导航控制器，而且`UINavigationBar` 是显示,那么`y = -64`，如果有导航控制器，但`UINavigationBar`隐藏,那么`y = -20`可以通过这个来判断导航栏是否隐藏；
  -  当然这个确实麻烦点，可以使用 我之前的文章 [任意NSObject及其子类中获取当前显示的控制器](http://www.jianshu.com/p/dcd26e1ab30f) 此时可以获取当前显示的控制器，然后判断NavigationBar 显示隐藏
  -  当然，还有一种办法，不需要去手动判断， `UITableView` 有 还有一个隐藏属性 `wrapperView` 这个 view 可以在 `debug view Hieratrchy` 里面看到层级结构，通过实测，这个会随着导航栏显示隐藏 来改变 y 的偏移，因此直接将无数据或者无网络页面添加到 `wrapperView` 上就可以了
- 判断TabBar：本来打算通过 `[UITabBar appearance]` 来获取，发现虽然不会报错，但测试发现没任何效果，通过断点po提示 `<_UIAppearance:0x17025b000> <Customizable class: UITabBar> with invocations (null)>` 是空的，不能获取到，当然 `[UINavigationBar appearance]` 也没效果，所以此时使用 [任意NSObject及其子类中获取当前显示的控制器](http://www.jianshu.com/p/dcd26e1ab30f) 来判断TabBar是否显示

```
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
```

>5、**获取GIF 图片 每一帧播放时长**，通过一个key `kCGImagePropertyGIFUnclampedDelayTime` 可以获取，然后拼接起来，播放GIF 图片

```
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
```

##五、总结

- 1、加载GIF 图片内存占用挺大，特别是缓存到内存中，内存会飙升，注意使用，测试发现`SDWebImage` 也会出现内存飙升，`YYImageCache` 的话就优化很多，待优化

- 2、分类中使用 `[UITabBar appearance]` 和 `[UINavigationBar appearance]` 都不能获取对象，断点po提示`<_UIAppearance:0x17025b000> <Customizable class: UITabBar> with invocations (null)>`

- 3、因为判断网络是通过获取状态栏信息来判断，如果 是 CMCC 连接的WI-FI，就不能正确判断网络是否已联网

- 4、此框架零耦合，方便移植，使用方便，只需要设置 `fl_noData_image` 和  `fl_noNetwork_image` ，只要调用 `reloadData` 就会自动判断需要显示什么界面

- 4、上文中提到的功能点都实现了，简单的功能，但做了详细的分析，从需求确定-功能分析-技术实现都做了详细的分析，封装的思想才是关键，开源不单单是代码，更多的是封装的思想

- 5、具体实现代码比较多，本文就不一一详细讲解，Demo 中有 对应的注释，**欢迎大家去[我的简书](http://www.jianshu.com/users/fe5700cfb223/latest_articles)关注我，喜欢给个like 和 star**，会随时开源~
