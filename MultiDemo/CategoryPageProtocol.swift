import UIKit

// MARK: - 分类页面协议
/// 每个分类模块需要实现此协议
protocol CategoryPageProtocol: UIViewController {
    /// 分类标题
    static var categoryTitle: String { get }
    
    /// 获取当前激活的可滚动子视图（用于嵌套滚动）
    func getCurrentScrollChild() -> NestedScrollChildProtocol?
}

// MARK: - 分类页面配置
/// 用于配置分类页面，支持懒加载
struct CategoryPageConfig {
    let title: String
    let pageFactory: () -> CategoryPageProtocol
    
    init(title: String, pageFactory: @escaping () -> CategoryPageProtocol) {
        self.title = title
        self.pageFactory = pageFactory
    }
}

// MARK: - 分类页面管理器
/// 管理分类页面的懒加载
class CategoryPageManager {
    
    private var configs: [CategoryPageConfig] = []
    private var cachedPages: [Int: CategoryPageProtocol] = [:]
    
    weak var scrollManager: NestedScrollManager?
    
    /// 配置分类页面
    func configure(with configs: [CategoryPageConfig]) {
        self.configs = configs
        self.cachedPages.removeAll()
    }
    
    /// 获取分类数量
    var count: Int {
        return configs.count
    }
    
    /// 获取分类标题
    func title(at index: Int) -> String? {
        guard index >= 0 && index < configs.count else { return nil }
        return configs[index].title
    }
    
    /// 获取所有标题
    var allTitles: [String] {
        return configs.map { $0.title }
    }
    
    /// 按需获取页面（懒加载）
    func page(at index: Int) -> CategoryPageProtocol? {
        guard index >= 0 && index < configs.count else { return nil }
        
        // 如果已缓存，直接返回
        if let cachedPage = cachedPages[index] {
            return cachedPage
        }
        
        // 创建新页面
        let page = configs[index].pageFactory()
        cachedPages[index] = page
        
        print("[CategoryPageManager] Created page at index \(index): \(configs[index].title)")
        
        return page
    }
    
    /// 检查页面是否已创建
    func isPageCreated(at index: Int) -> Bool {
        return cachedPages[index] != nil
    }
    
    /// 获取已创建的页面（不触发创建）
    func cachedPage(at index: Int) -> CategoryPageProtocol? {
        return cachedPages[index]
    }
}
