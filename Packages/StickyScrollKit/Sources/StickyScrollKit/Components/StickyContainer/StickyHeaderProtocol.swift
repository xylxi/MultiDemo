import UIKit

// MARK: - ================== 吸顶容器协议 ==================

// MARK: - 吸顶头部视图协议
/// 作为吸顶容器的头部视图需要实现此协议
public protocol StickyHeaderViewProtocol: UIView {
    /// 头部视图的首选高度（intrinsic height）
    /// 如果返回 nil，则使用 Auto Layout 计算的高度
    var preferredHeight: CGFloat? { get }
}

// 默认实现
public extension StickyHeaderViewProtocol {
    var preferredHeight: CGFloat? { nil }
}

// MARK: - 吸顶菜单视图协议
/// 作为吸顶容器的菜单视图需要实现此协议
public protocol StickyMenuViewProtocol: UIView {
    /// 菜单高度
    var menuHeight: CGFloat { get }
    
    /// 选中菜单项
    func selectItem(at index: Int, animated: Bool)
    
    /// 设置菜单选择回调
    var onItemSelected: ((Int) -> Void)? { get set }
}

// MARK: - 吸顶页面协议
/// 作为吸顶容器的分页内容需要实现此协议
public protocol StickyPageProtocol: UIViewController {
    
    /// 获取当前可滚动的子视图（用于嵌套滚动）
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    
    /// 设置滚动事件回调
    func setScrollCallbacks(
        onScroll: @escaping (UIScrollView) -> Void,
        onChildChanged: @escaping (NestedScrollChildProtocol) -> Void
    )
    
    /// 获取内部所有水平滚动的 ScrollView（用于手势排除）
    func getAllHorizontalScrollViews() -> [UIScrollView]
    
    // MARK: - 页面生命周期（可选）
    
    /// 页面即将显示
    func pageWillAppear()
    
    /// 页面已经显示
    func pageDidAppear()
    
    /// 页面即将隐藏
    func pageWillDisappear()
    
    /// 页面已经隐藏
    func pageDidDisappear()
}

// 默认实现
public extension StickyPageProtocol {
    func pageWillAppear() {}
    func pageDidAppear() {}
    func pageWillDisappear() {}
    func pageDidDisappear() {}
}

// MARK: - 吸顶容器数据源
/// 提供吸顶容器的页面数据
public protocol StickyContainerDataSource: AnyObject {
    /// 页面数量
    func numberOfPages(in container: StickyHeaderContainerView) -> Int
    
    /// 页面标题（用于菜单显示）
    func stickyContainer(_ container: StickyHeaderContainerView, titleForPageAt index: Int) -> String
    
    /// 创建页面（懒加载时调用）
    func stickyContainer(_ container: StickyHeaderContainerView, pageAt index: Int) -> StickyPageProtocol
}

// MARK: - 吸顶容器代理
/// 吸顶容器的事件回调
public protocol StickyContainerDelegate: AnyObject {
    /// 页面切换完成
    func stickyContainer(_ container: StickyHeaderContainerView, didSwitchToPageAt index: Int)
    
    /// 滚动进度变化（用于更新外部 UI，如导航栏透明度）
    /// - Parameters:
    ///   - progress: 滚动进度，0 表示顶部，1 表示吸顶
    func stickyContainer(_ container: StickyHeaderContainerView, scrollProgressDidChange progress: CGFloat)
    
    /// 页面已加载
    func stickyContainer(_ container: StickyHeaderContainerView, didLoadPageAt index: Int, page: StickyPageProtocol)
}

// 可选实现
public extension StickyContainerDelegate {
    func stickyContainer(_ container: StickyHeaderContainerView, scrollProgressDidChange progress: CGFloat) {}
    func stickyContainer(_ container: StickyHeaderContainerView, didLoadPageAt index: Int, page: StickyPageProtocol) {}
}

// MARK: - 吸顶容器配置
/// 吸顶容器的配置参数
public struct StickyContainerConfig {
    /// 是否启用菜单区域
    public var menuEnabled: Bool
    
    /// 菜单高度
    public var menuHeight: CGFloat
    
    /// 吸顶偏移量（顶部始终显示的高度，如导航栏）
    public var stickyOffset: CGFloat
    
    /// 初始选中的页面索引
    public var initialPageIndex: Int
    
    /// 是否启用弹性效果
    public var bounces: Bool
    
    public init(
        menuEnabled: Bool = true,
        menuHeight: CGFloat = 48,
        stickyOffset: CGFloat = 0,
        initialPageIndex: Int = 0,
        bounces: Bool = true
    ) {
        self.menuEnabled = menuEnabled
        self.menuHeight = menuHeight
        self.stickyOffset = stickyOffset
        self.initialPageIndex = initialPageIndex
        self.bounces = bounces
    }
}

