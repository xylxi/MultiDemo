/// StickyScrollKit
/// 
/// 一个通用的 iOS 吸顶滚动组件库，支持嵌套滚动、吸顶效果和分页内容。
///
/// ## 主要组件
///
/// ### Core - 嵌套滚动核心
/// - `NestedScrollChildProtocol`: 子视图协议
/// - `NestedScrollParentProtocol`: 父视图协议
/// - `NestedScrollContainerProtocol`: 容器协议（约定大于配置）
/// - `NestedScrollManager`: 嵌套滚动管理器
/// - `NestedParentScrollView`: 支持手势排除的 ScrollView
///
/// ### Components/StickyContainer - 吸顶容器
/// - `StickyHeaderContainerView`: 通用吸顶容器视图
/// - `StickyContainerConfig`: 容器配置
/// - `StickyContainerDataSource`: 数据源协议
/// - `StickyContainerDelegate`: 代理协议
/// - `StickyPageProtocol`: 页面协议
/// - `StickyMenuViewProtocol`: 菜单协议
///
/// ## 使用示例
///
/// ```swift
/// import StickyScrollKit
///
/// class MyViewController: UIViewController {
///     private lazy var stickyContainer = StickyHeaderContainerView()
///     
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         
///         stickyContainer.dataSource = self
///         stickyContainer.delegate = self
///         
///         let config = StickyContainerConfig(
///             menuHeight: 48,
///             stickyOffset: view.safeAreaInsets.top + 44
///         )
///         
///         // 传入自定义菜单（实现 StickyMenuViewProtocol），或传 nil 表示无菜单
///         stickyContainer.configure(with: config, headerView: myHeaderView, menuView: customMenu)
///     }
/// }
/// ```

// 此文件作为模块入口点，提供文档说明
// 所有组件通过各自的文件自动导出（因为都标记为 public）

