import UIKit

// MARK: - ================== 资产流协议规范 ==================

// MARK: - 滚动事件回调类型
/// 子视图滚动事件回调
public typealias ScrollEventHandler = (UIScrollView) -> Void
/// 当前子视图变更回调
public typealias CurrentChildChangedHandler = (NestedScrollChildProtocol) -> Void

// MARK: - 资产流页面协议
/// 每个资产流模块（如出境、创作）必须实现此协议
/// 用于规范资产流页面的基本行为
/// 
/// 解耦设计：通过闭包回调与父容器通信，不直接依赖 NestedScrollManager
public protocol AssetFlowPageProtocol: UIViewController {
    
    /// 获取当前可滚动的子视图（用于嵌套滚动联动）
    /// - Returns: 当前激活的可滚动视图，如果没有则返回 nil
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    
    /// 设置滚动事件回调（解耦方式）
    /// - Parameters:
    ///   - onScroll: 子视图滚动时的回调
    ///   - onChildChanged: 当前激活子视图变更时的回调
    func setScrollCallbacks(onScroll: @escaping ScrollEventHandler, 
                            onChildChanged: @escaping CurrentChildChangedHandler)
    
    /// 获取内部所有水平滚动的 CollectionView（用于手势排除）
    /// - Returns: 所有需要排除手势冲突的 CollectionView
    func getAllHorizontalScrollViews() -> [UIScrollView]
}

// MARK: - 资产流配置
/// 用于配置单个资产流模块
public struct AssetFlowConfig {
    
    /// 分类标题（显示在菜单上）
    public let title: String
    
    /// 页面工厂（懒加载创建）
    public let pageFactory: () -> AssetFlowPageProtocol
    
    public init(title: String, pageFactory: @escaping () -> AssetFlowPageProtocol) {
        self.title = title
        self.pageFactory = pageFactory
    }
}

// MARK: - 资产流数据源协议
/// ProfileViewController 通过此协议获取资产流配置
public protocol AssetFlowDataSource: AnyObject {
    
    /// 返回资产流配置列表
    /// - Returns: 资产流配置数组
    func assetFlowConfigs() -> [AssetFlowConfig]
}

// MARK: - 资产流代理协议
/// 资产流事件回调
public protocol AssetFlowDelegate: AnyObject {
    
    /// 资产流切换时回调
    /// - Parameters:
    ///   - index: 切换到的索引
    ///   - title: 切换到的分类标题
    func assetFlowDidSwitchTo(index: Int, title: String)
    
    /// 资产流页面首次加载时回调
    /// - Parameters:
    ///   - index: 加载的索引
    ///   - page: 加载的页面
    func assetFlowDidLoadPage(at index: Int, page: AssetFlowPageProtocol)
}

// MARK: - 默认实现（可选方法）
public extension AssetFlowDelegate {
    func assetFlowDidSwitchTo(index: Int, title: String) {}
    func assetFlowDidLoadPage(at index: Int, page: AssetFlowPageProtocol) {}
}
