import UIKit
import SnapKit
import StickyScrollKit
import ViewPagerKit

// MARK: - ================== 使用 ViewPager 组件重构后的版本 ==================
// 这是一个示例文件，展示如何使用通用 ViewPager 组件
// 对比原版 AppearanceViewController，代码量大幅减少

/// 出境模块 ViewController（使用 ViewPager 组件）
///
/// ✅ 优势：
/// - 代码量减少 60%+
/// - 逻辑更清晰
/// - 复用性更强
class AppearanceViewControllerRefactored: UIViewController, AssetFlowPageProtocol {
    
    // MARK: - AssetFlowPageProtocol
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        return viewPager.currentViewController as? NestedScrollChildProtocol
    }
    
    func setScrollCallbacks(onScroll: @escaping (UIScrollView) -> Void,
                            onChildChanged: @escaping (NestedScrollChildProtocol) -> Void) {
        // 约定大于配置：不再需要手动绑定闭包
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [viewPager.collectionView]
    }
    
    // MARK: - 子分类配置（Mock 更多数据测试内存管理）
    private let subCategories: [(title: String, color: UIColor)] = [
        ("作品", .systemBlue),
        ("喜欢", UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1)),
        ("点赞", .systemTeal),
        ("收藏", .systemOrange),
        ("历史", .systemPurple),
        ("推荐", .systemPink),
        ("关注", .systemGreen),
        ("热门", .systemRed),
        ("最新", .systemIndigo),
        ("精选", .systemYellow)
    ]
    
    // MARK: - UI
    
    /// ⭐️ 核心：使用 ViewPager 组件（来自独立的 ViewPagerKit）
    private lazy var viewPager: ViewPager = {
        let pager = ViewPager(config: ViewPagerConfig(
            tabBarHeight: 44,
            showTabBar: true,
            isScrollEnabled: true,
            // ⭐️ 内存管理：只保留当前页 ± 1 页（10 个 Tab 只会缓存 3 个页面）
            cachePolicy: .offscreenLimit(1)
        ))
        pager.dataSource = self
        pager.delegate = self
        return pager
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewPager.reloadData()  // 加载数据
        
        print("📱 [Demo] 共 \(subCategories.count) 个 Tab，使用 offscreenLimit(1) 策略")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // ⭐️ 内存警告时清理缓存
        viewPager.clearCache(keepCurrent: true)
        print("⚠️ [Demo] 收到内存警告，已清理 ViewPager 缓存")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(viewPager)
        
        viewPager.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - 页面生命周期
    func pageWillAppear() { }
    func pageDidAppear() { }
    func pageWillDisappear() { }
    func pageDidDisappear() { }
}

// MARK: - ViewPagerDataSource

extension AppearanceViewControllerRefactored: ViewPagerDataSource {
    
    /// 返回页面数量
    func numberOfPages(in viewPager: ViewPager) -> Int {
        return subCategories.count
    }
    
    /// 返回每页标题
    func viewPager(_ viewPager: ViewPager, titleForPageAt index: Int) -> String {
        return subCategories[index].title
    }
    
    /// 创建每页的 ViewController
    func viewPager(_ viewPager: ViewPager, viewControllerForPageAt index: Int) -> UIViewController {
        let category = subCategories[index]
        let path = "出境 > \(category.title)"
        return WorksFlowViewController(categoryPath: path, color: category.color)
    }
}

// MARK: - ViewPagerDelegate

extension AppearanceViewControllerRefactored: ViewPagerDelegate {
    
    /// 页面切换回调
    func viewPager(_ viewPager: ViewPager, didScrollToPageAt index: Int) {
        print("📄 切换到页面: \(subCategories[index].title)")
    }
}

