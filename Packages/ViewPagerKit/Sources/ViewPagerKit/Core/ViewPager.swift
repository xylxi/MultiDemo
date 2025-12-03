import UIKit
import SnapKit

// MARK: - ================== ViewPager 核心组件 ==================

// MARK: - ViewPager 协议

/// ViewPager 页面协议（可选）
/// 实现此协议可以接收页面生命周期回调
public protocol ViewPagerPageProtocol: UIViewController {
    /// 页面即将显示
    func pageWillAppear()
    /// 页面已显示
    func pageDidAppear()
    /// 页面即将消失
    func pageWillDisappear()
    /// 页面已消失
    func pageDidDisappear()
}

/// 默认实现（可选）
public extension ViewPagerPageProtocol {
    func pageWillAppear() {}
    func pageDidAppear() {}
    func pageWillDisappear() {}
    func pageDidDisappear() {}
}

/// 可滚动页面协议（可选）
/// 实现此协议可以在页面被回收时保存滚动位置，重新加载时恢复
public protocol ViewPagerScrollablePageProtocol: UIViewController {
    /// 返回页面的主 ScrollView（用于保存/恢复滚动位置）
    var pageScrollView: UIScrollView? { get }
}

// MARK: - ViewPager 代理

public protocol ViewPagerDelegate: AnyObject {
    /// 页面切换完成回调
    func viewPager(_ viewPager: ViewPager, didScrollToPageAt index: Int)
    /// 页面将要切换回调
    func viewPager(_ viewPager: ViewPager, willScrollToPageAt index: Int)
    /// 滚动中回调（可用于自定义联动效果）
    func viewPager(_ viewPager: ViewPager, didScrollWithProgress progress: CGFloat, fromIndex: Int, toIndex: Int)
}

/// 默认实现（可选）
public extension ViewPagerDelegate {
    func viewPager(_ viewPager: ViewPager, willScrollToPageAt index: Int) {}
    func viewPager(_ viewPager: ViewPager, didScrollWithProgress progress: CGFloat, fromIndex: Int, toIndex: Int) {}
}

// MARK: - ViewPager 数据源

public protocol ViewPagerDataSource: AnyObject {
    /// 页面数量
    func numberOfPages(in viewPager: ViewPager) -> Int
    /// 页面标题（用于 TabBar）
    func viewPager(_ viewPager: ViewPager, titleForPageAt index: Int) -> String
    /// 创建页面 ViewController
    func viewPager(_ viewPager: ViewPager, viewControllerForPageAt index: Int) -> UIViewController
}

// MARK: - 页面缓存策略

/// 页面缓存策略
public enum PageCachePolicy {
    /// 缓存所有访问过的页面（适合页面少的场景，如 3-5 个 Tab）
    case cacheAll
    
    /// 只保留当前页面 ± limit 范围内的页面（推荐，类似 Android ViewPager2）
    /// - Parameter limit: 预加载的页面数量（默认 1，即保留前后各 1 页）
    case offscreenLimit(_ limit: Int)
    
    /// LRU 缓存，最多保留 maxCount 个页面
    /// - Parameter maxCount: 最大缓存页面数（默认 3）
    case lru(maxCount: Int)
    
    /// 不缓存，每次都重新创建（内存最优，但性能较差）
    case noCache
}

// MARK: - ViewPager 配置

public struct ViewPagerConfig {
    /// Tab 栏高度
    public var tabBarHeight: CGFloat
    /// 是否显示 Tab 栏
    public var showTabBar: Bool
    /// 是否启用滑动切换
    public var isScrollEnabled: Bool
    /// 页面切换动画时长
    public var animationDuration: TimeInterval
    /// Tab 栏配置
    public var tabBarConfig: TabBarConfig
    /// 页面缓存策略（⭐️ 内存管理关键配置）
    public var cachePolicy: PageCachePolicy
    
    public init(
        tabBarHeight: CGFloat = 44,
        showTabBar: Bool = true,
        isScrollEnabled: Bool = true,
        animationDuration: TimeInterval = 0.25,
        tabBarConfig: TabBarConfig = .default,
        cachePolicy: PageCachePolicy = .offscreenLimit(1)  // 默认只保留前后各 1 页
    ) {
        self.tabBarHeight = tabBarHeight
        self.showTabBar = showTabBar
        self.isScrollEnabled = isScrollEnabled
        self.animationDuration = animationDuration
        self.tabBarConfig = tabBarConfig
        self.cachePolicy = cachePolicy
    }
    
    public static let `default` = ViewPagerConfig()
}

// MARK: - ViewPager

/// 通用 ViewPager 组件
/// 类似 Android 的 ViewPager，实现 Tab + 横向分页滑动效果
///
/// ## 特性
/// - 支持 Tab 栏 + 页面双向联动
/// - 页面懒加载 & 缓存
/// - 可自定义 Tab 栏样式
/// - 支持页面生命周期回调
/// - 滚动进度回调（可实现自定义动画）
///
/// ## 使用方式
/// ```swift
/// let viewPager = ViewPager()
/// viewPager.dataSource = self
/// viewPager.delegate = self
/// viewPager.reloadData()
/// ```
public class ViewPager: UIView {
    
    // MARK: - Public Properties
    
    public weak var delegate: ViewPagerDelegate?
    public weak var dataSource: ViewPagerDataSource?
    
    /// 配置
    public var config: ViewPagerConfig = .default {
        didSet { updateConfig() }
    }
    
    /// 当前页面索引
    public private(set) var currentIndex: Int = 0
    
    /// 获取当前页面的 ViewController
    public var currentViewController: UIViewController? {
        return loadedPages[currentIndex]
    }
    
    /// 获取 TabBar（可自定义样式）
    public var tabBar: ViewPagerTabBar { _tabBar }
    
    /// 获取横向滚动的 CollectionView（可自定义行为）
    public var collectionView: UICollectionView { _collectionView }
    
    // MARK: - Private Properties
    
    private var loadedPages: [Int: UIViewController] = [:]
    private var numberOfPages: Int = 0
    private var isScrollingByCode: Bool = false
    
    /// LRU 访问顺序记录（用于 LRU 缓存策略）
    private var pageAccessOrder: [Int] = []
    
    /// 保存的滚动位置（页面回收时保存，重新加载时恢复）
    private var savedContentOffsets: [Int: CGPoint] = [:]
    
    // MARK: - UI Components
    
    private lazy var _tabBar: ViewPagerTabBar = {
        let tabBar = ViewPagerTabBar(config: config.tabBarConfig)
        tabBar.delegate = self
        return tabBar
    }()
    
    private lazy var _collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(ViewPagerCell.self, forCellWithReuseIdentifier: ViewPagerCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()
    
    private var tabBarHeightConstraint: Constraint?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    public convenience init(config: ViewPagerConfig) {
        self.init(frame: .zero)
        self.config = config
        updateConfig()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(_tabBar)
        addSubview(_collectionView)
        
        _tabBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            tabBarHeightConstraint = make.height.equalTo(config.tabBarHeight).constraint
        }
        
        _collectionView.snp.makeConstraints { make in
            make.top.equalTo(_tabBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func updateConfig() {
        tabBarHeightConstraint?.update(offset: config.showTabBar ? config.tabBarHeight : 0)
        _tabBar.isHidden = !config.showTabBar
        _tabBar.config = config.tabBarConfig
        _collectionView.isScrollEnabled = config.isScrollEnabled
    }
    
    // MARK: - Public Methods
    
    /// 重新加载数据
    public func reloadData() {
        guard let dataSource = dataSource else { return }
        
        // 清理旧页面
        loadedPages.values.forEach { vc in
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        loadedPages.removeAll()
        pageAccessOrder.removeAll()
        savedContentOffsets.removeAll()  // 重置时清除保存的滚动位置
        
        // 获取页面数量
        numberOfPages = dataSource.numberOfPages(in: self)
        
        // 配置 TabBar
        if config.showTabBar {
            var tabItems: [TabItem] = []
            for i in 0..<numberOfPages {
                let title = dataSource.viewPager(self, titleForPageAt: i)
                tabItems.append(TabItem(title: title))
            }
            _tabBar.configure(with: tabItems)
        }
        
        // 重新加载 CollectionView
        _collectionView.reloadData()
        
        // 重置到第一页
        if numberOfPages > 0 {
            currentIndex = 0
            _tabBar.selectItem(at: 0, animated: false)
        }
    }
    
    /// 滚动到指定页面
    /// - Parameters:
    ///   - index: 目标页面索引
    ///   - animated: 是否动画
    public func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < numberOfPages else { return }
        guard index != currentIndex else { return }
        
        delegate?.viewPager(self, willScrollToPageAt: index)
        
        let previousIndex = currentIndex
        currentIndex = index
        isScrollingByCode = true
        
        // 更新 TabBar
        _tabBar.selectItem(at: index, animated: animated)
        
        // 滚动到对应页面
        _collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
        
        // 通知页面生命周期
        notifyPageTransition(from: previousIndex, to: index)
        
        if !animated {
            isScrollingByCode = false
            delegate?.viewPager(self, didScrollToPageAt: index)
        }
    }
    
    /// 获取指定索引的页面 ViewController
    public func viewController(at index: Int) -> UIViewController? {
        return loadedPages[index]
    }
    
    // MARK: - Private Methods
    
    private func loadPage(at index: Int) -> UIViewController? {
        guard let dataSource = dataSource else { return nil }
        
        // 已加载则直接返回，并更新访问顺序
        if let page = loadedPages[index] {
            updateAccessOrder(for: index)
            return page
        }
        
        // 创建新页面
        let viewController = dataSource.viewPager(self, viewControllerForPageAt: index)
        
        // 添加为子控制器（需要找到父 ViewController）
        if let parentVC = findParentViewController() {
            parentVC.addChild(viewController)
            viewController.didMove(toParent: parentVC)
        }
        
        loadedPages[index] = viewController
        updateAccessOrder(for: index)
        
        // ⭐️ 恢复之前保存的滚动位置
        restoreContentOffset(for: viewController, at: index)
        
        // ⭐️ 根据缓存策略回收页面
        // 注意：这里要传 self.currentIndex（当前显示的页面），而不是 index（正在加载的页面）
        // 否则会导致当前显示的页面被错误回收！
        recyclePages(currentIndex: self.currentIndex)
        
        return viewController
    }
    
    // MARK: - 内存管理
    
    /// 更新页面访问顺序（用于 LRU）
    private func updateAccessOrder(for index: Int) {
        pageAccessOrder.removeAll { $0 == index }
        pageAccessOrder.append(index)
    }
    
    /// 根据缓存策略回收页面
    private func recyclePages(currentIndex: Int) {
        switch config.cachePolicy {
        case .cacheAll:
            // 不回收，保留所有页面
            break
            
        case .offscreenLimit(let limit):
            recycleWithOffscreenLimit(limit, currentIndex: currentIndex)
            
        case .lru(let maxCount):
            recycleWithLRU(maxCount: maxCount)
            
        case .noCache:
            recycleAllExceptCurrent(currentIndex: currentIndex)
        }
    }
    
    /// 只保留当前页面 ± limit 范围内的页面
    private func recycleWithOffscreenLimit(_ limit: Int, currentIndex: Int) {
        let minIndex = max(0, currentIndex - limit)
        let maxIndex = min(numberOfPages - 1, currentIndex + limit)
        let keepRange = minIndex...maxIndex
        
        let indicesToRemove = loadedPages.keys.filter { !keepRange.contains($0) }
        
        for index in indicesToRemove {
            removePage(at: index)
        }
        
        #if DEBUG
        if !indicesToRemove.isEmpty {
            print("🗑️ [ViewPager] 回收页面: \(indicesToRemove), 保留范围: \(keepRange)")
        }
        #endif
    }
    
    /// LRU 缓存策略
    private func recycleWithLRU(maxCount: Int) {
        while loadedPages.count > maxCount && pageAccessOrder.count > maxCount {
            // 移除最早访问的页面
            let oldestIndex = pageAccessOrder.removeFirst()
            
            // 不移除当前显示的页面
            if oldestIndex != currentIndex {
                removePage(at: oldestIndex)
                
                #if DEBUG
                print("🗑️ [ViewPager] LRU 回收页面: \(oldestIndex)")
                #endif
            } else {
                // 当前页面放回队列末尾
                pageAccessOrder.append(oldestIndex)
            }
        }
    }
    
    /// 只保留当前页面
    private func recycleAllExceptCurrent(currentIndex: Int) {
        let indicesToRemove = loadedPages.keys.filter { $0 != currentIndex }
        
        for index in indicesToRemove {
            removePage(at: index)
        }
    }
    
    /// 移除指定页面
    private func removePage(at index: Int) {
        guard let viewController = loadedPages[index] else { return }
        
        // ⭐️ 保存滚动位置（回收前）
        saveContentOffset(for: viewController, at: index)
        
        // 通知页面消失
        if let pageVC = viewController as? ViewPagerPageProtocol {
            pageVC.pageWillDisappear()
            pageVC.pageDidDisappear()
        }
        
        // 从父控制器移除
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        
        // 从缓存移除
        loadedPages.removeValue(forKey: index)
        pageAccessOrder.removeAll { $0 == index }
    }
    
    // MARK: - 滚动位置保存/恢复
    
    /// 保存页面的滚动位置
    private func saveContentOffset(for viewController: UIViewController, at index: Int) {
        let scrollView: UIScrollView?
        
        // 优先使用协议方法获取 scrollView
        if let scrollablePage = viewController as? ViewPagerScrollablePageProtocol {
            scrollView = scrollablePage.pageScrollView
        } else {
            // 自动查找第一个 UIScrollView
            scrollView = findScrollView(in: viewController.view)
        }
        
        if let sv = scrollView {
            savedContentOffsets[index] = sv.contentOffset
            #if DEBUG
            print("💾 [ViewPager] 保存页面 \(index) 滚动位置: \(sv.contentOffset)")
            #endif
        }
    }
    
    /// 恢复页面的滚动位置
    private func restoreContentOffset(for viewController: UIViewController, at index: Int) {
        guard let savedOffset = savedContentOffsets[index] else { return }
        
        let scrollView: UIScrollView?
        
        // 优先使用协议方法获取 scrollView
        if let scrollablePage = viewController as? ViewPagerScrollablePageProtocol {
            scrollView = scrollablePage.pageScrollView
        } else {
            // 自动查找第一个 UIScrollView
            scrollView = findScrollView(in: viewController.view)
        }
        
        if let sv = scrollView {
            // 延迟恢复，确保 layout 完成
            DispatchQueue.main.async {
                sv.contentOffset = savedOffset
                #if DEBUG
                print("📍 [ViewPager] 恢复页面 \(index) 滚动位置: \(savedOffset)")
                #endif
            }
        }
    }
    
    /// 递归查找视图中的第一个 UIScrollView
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        return nil
    }
    
    /// 手动清理所有缓存（可在内存警告时调用）
    public func clearCache(keepCurrent: Bool = true) {
        if keepCurrent {
            recycleAllExceptCurrent(currentIndex: currentIndex)
        } else {
            for index in loadedPages.keys {
                removePage(at: index)
            }
        }
        
        #if DEBUG
        print("🧹 [ViewPager] 清理缓存完成，当前缓存页面数: \(loadedPages.count)")
        #endif
    }
    
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    private func notifyPageTransition(from previousIndex: Int, to newIndex: Int) {
        guard previousIndex != newIndex else { return }
        
        // 通知旧页面消失
        if let previousVC = loadedPages[previousIndex] as? ViewPagerPageProtocol {
            previousVC.pageWillDisappear()
            previousVC.pageDidDisappear()
        }
        
        // 通知新页面出现
        if let newVC = loadedPages[newIndex] as? ViewPagerPageProtocol {
            newVC.pageWillAppear()
            newVC.pageDidAppear()
        }
    }
    
    private func updateCurrentIndex(from scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        
        if index != currentIndex && index >= 0 && index < numberOfPages {
            let previousIndex = currentIndex
            currentIndex = index
            
            // 同步 TabBar
            _tabBar.selectItem(at: index)
            
            // 通知页面生命周期
            notifyPageTransition(from: previousIndex, to: index)
            
            // ⭐️ 更新访问顺序并回收页面
            updateAccessOrder(for: index)
            recyclePages(currentIndex: index)
            
            // 回调代理
            delegate?.viewPager(self, didScrollToPageAt: index)
        }
    }
}

// MARK: - ViewPagerTabBarDelegate

extension ViewPager: ViewPagerTabBarDelegate {
    public func tabBar(_ tabBar: ViewPagerTabBar, didSelectItemAt index: Int) {
        scrollToPage(index, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ViewPager: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPages
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewPagerCell.reuseId, for: indexPath) as! ViewPagerCell
        
        if let page = loadPage(at: indexPath.item) {
            cell.configure(with: page.view)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ViewPager: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isScrollingByCode else { return }
        guard scrollView.bounds.width > 0 else { return }
        
        // 计算滚动进度
        let offsetX = scrollView.contentOffset.x
        let pageWidth = scrollView.bounds.width
        let progress = offsetX / pageWidth
        
        let fromIndex = Int(floor(progress))
        let toIndex = Int(ceil(progress))
        let localProgress = progress - CGFloat(fromIndex)
        
        if fromIndex >= 0 && toIndex < numberOfPages && fromIndex != toIndex {
            delegate?.viewPager(self, didScrollWithProgress: localProgress, fromIndex: fromIndex, toIndex: toIndex)
            
            // 更新指示器位置（平滑过渡）
            _tabBar.updateIndicator(progress: localProgress, fromIndex: fromIndex, toIndex: toIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndex(from: scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollingByCode = false
        updateCurrentIndex(from: scrollView)
        delegate?.viewPager(self, didScrollToPageAt: currentIndex)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ViewPager: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - ViewPagerCell

private class ViewPagerCell: UICollectionViewCell {
    static let reuseId = "ViewPagerCell"
    
    private var currentContentView: UIView?
    
    func configure(with contentView: UIView) {
        // 避免重复添加同一个 view
        if currentContentView === contentView { return }
        
        // 移除旧的 view
        currentContentView?.removeFromSuperview()
        currentContentView = contentView
        
        // 添加新的 view
        self.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 不移除 contentView，因为页面是被缓存复用的
    }
}

