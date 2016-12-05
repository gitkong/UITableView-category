/*
 * author 孔凡列
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 微信公众号 原创技术分享
 * 喜欢就给个like 和 star 喔~
 */

#import <UIKit/UIKit.h>

@interface UITableView (fl_category)
/**
 *  @author gitKong
 *
 *  没有数据显示的图片
 *
 *  可传入 本地图片名 或者 网络URL （包括gif）如果是网络URL，内部自动缓存
 */
@property (nonatomic,copy)NSString *fl_noData_image;
/**
 *  @author gitKong
 *
 *  没有网络显示的图片
 *
 *  可传入 本地图片名 或者 网络URL （包括gif）如果是网络URL，内部自动缓存
 */
@property (nonatomic,copy)NSString *fl_noNetwork_image;
/**
 *  @author gitKong
 *
 *  没有网络或者没有数据显示界面的点击事件
 */
- (void)fl_imageViewClickOperation:(void(^)())clickOperation;

@end
