/// ViewPagerKit
///
/// 一个独立的 iOS ViewPager 组件库，类似 Android 的 ViewPager。
/// 实现 Tab + 横向分页滑动效果。
///
/// ## 主要组件
///
/// ### Core - ViewPager 核心
/// - `ViewPager`: 通用 ViewPager 视图
/// - `ViewPagerConfig`: 配置选项
/// - `ViewPagerDataSource`: 数据源协议
/// - `ViewPagerDelegate`: 代理协议
/// - `ViewPagerPageProtocol`: 页面生命周期协议
///
/// ### TabBar - Tab 栏组件
/// - `ViewPagerTabBar`: Tab 栏视图
/// - `ViewPagerTabBarDelegate`: Tab 代理
/// - `TabItem`: Tab 项模型
///
/// ## 使用示例
///
/// ```swift
/// import ViewPagerKit
///
/// class MyViewController: UIViewController, ViewPagerDataSource {
///     private lazy var viewPager = ViewPager()
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         viewPager.dataSource = self
///         viewPager.reloadData()
///     }
///
///     func numberOfPages(in viewPager: ViewPager) -> Int { return 3 }
///     func viewPager(_ viewPager: ViewPager, titleForPageAt index: Int) -> String { ... }
///     func viewPager(_ viewPager: ViewPager, viewControllerForPageAt index: Int) -> UIViewController { ... }
/// }
/// ```

// 此文件作为模块入口点，提供文档说明
// 所有组件通过各自的文件自动导出（因为都标记为 public）

