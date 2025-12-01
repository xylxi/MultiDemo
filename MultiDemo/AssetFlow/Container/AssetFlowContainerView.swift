import UIKit
import SnapKit

// MARK: - ================== 资产流容器 ==================

// MARK: - 资产流容器代理
protocol AssetFlowContainerDelegate: AnyObject {
    func assetFlowContainer(_ container: AssetFlowContainerView, didSwitchToIndex index: Int)
    func assetFlowContainer(_ container: AssetFlowContainerView, needsPageAt index: Int) -> AssetFlowPageProtocol?
}

// MARK: - 资产流容器视图
/// 包含菜单和分页容器的完整资产流区域
/// 
/// 解耦设计：不依赖 NestedScrollManager，由外部（ProfileViewController）负责绑定滚动回调
class AssetFlowContainerView: UIView {
    
    weak var delegate: AssetFlowContainerDelegate?
    
    private(set) var currentIndex: Int = 0
    private var previousIndex: Int = 0  // 记录上一个页面索引
    private var pageCount: Int = 0
    private var titles: [String] = []
    private var loadedPages: [Int: AssetFlowPageProtocol] = [:]
    private var isTransitioning: Bool = false  // 是否正在切换中
    private var initialIndex: Int = 0  // 记录初始索引，用于延迟加载优化
    private var hasPerformedInitialScroll: Bool = false  // 是否已完成初始滚动
    
    /// 菜单视图（外部可访问以自定义）
    let menuView: MenuView = {
        let menu = MenuView()
        menu.backgroundColor = .systemBackground
        return menu
    }()
    
    /// 分页 CollectionView
    private lazy var pageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(AssetFlowPageCell.self, forCellWithReuseIdentifier: AssetFlowPageCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        // 禁用预加载，避免不必要的页面初始化
        if #available(iOS 10.0, *) {
            cv.isPrefetchingEnabled = false
        }
        return cv
    }()
    
    /// 菜单高度
    var menuHeight: CGFloat = 48 {
        didSet {
            menuHeightConstraint?.update(offset: menuHeight)
        }
    }
    
    private var menuHeightConstraint: Constraint?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(menuView)
        addSubview(pageCollectionView)
        
        menuView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            menuHeightConstraint = make.height.equalTo(menuHeight).constraint
        }
        
        pageCollectionView.snp.makeConstraints { make in
            make.top.equalTo(menuView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        menuView.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 配置资产流（设置标题和数量，不立即创建页面）
    /// - Parameters:
    ///   - titles: 资产流标题数组
    ///   - initialIndex: 初始定位的索引（默认为 0）
    func configure(with titles: [String], initialIndex: Int = 0) {
        self.titles = titles
        self.pageCount = titles.count
        
        // 确保初始索引在有效范围内
        let validInitialIndex = max(0, min(initialIndex, titles.count > 0 ? titles.count - 1 : 0))
        self.currentIndex = validInitialIndex
        self.previousIndex = validInitialIndex
        self.initialIndex = validInitialIndex
        self.loadedPages.removeAll()
        self.isTransitioning = false
        self.hasPerformedInitialScroll = false
        
        let menuItems = titles.map { MenuItem(title: $0) }
        menuView.configure(with: menuItems)
        
        // 设置菜单选中项到初始索引
        if pageCount > 0 {
            menuView.selectItem(at: validInitialIndex, animated: false)
        }
        
        pageCollectionView.reloadData()
        
        // 滚动到初始索引位置（需要在布局完成后执行）
        if pageCount > 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // 确保 CollectionView 已经完成布局
                self.pageCollectionView.layoutIfNeeded()
                
                // 如果初始索引不是 0，先设置 contentOffset 避免预加载第一个页面
                // 然后再滚动到指定位置
                if validInitialIndex > 0 {
                    let offsetX = CGFloat(validInitialIndex) * self.pageCollectionView.bounds.width
                    self.pageCollectionView.contentOffset = CGPoint(x: offsetX, y: 0)
                    
                    // 确保滚动到正确位置
                    let indexPath = IndexPath(item: validInitialIndex, section: 0)
                    self.pageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
                
                // 标记已完成初始滚动
                self.hasPerformedInitialScroll = true
                
                // 通知初始页面显示
                self.notifyPageWillAppear(at: validInitialIndex)
                self.notifyPageDidAppear(at: validInitialIndex)
                
                // 通知 delegate 初始索引已设置
                self.delegate?.assetFlowContainer(self, didSwitchToIndex: validInitialIndex)
            }
        }
    }
    
    /// 滚动到指定页面
    func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < pageCount else { return }
        guard index != currentIndex else { return }
        
        // 通知旧页面即将隐藏
        notifyPageWillDisappear(at: currentIndex)
        // 通知新页面即将显示
        notifyPageWillAppear(at: index)
        
        previousIndex = currentIndex
        currentIndex = index
        isTransitioning = animated
        
        pageCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        menuView.selectItem(at: index, animated: animated)
        
        if !animated {
            // 无动画时立即触发 did 回调
            notifyPageDidDisappear(at: previousIndex)
            notifyPageDidAppear(at: index)
            delegate?.assetFlowContainer(self, didSwitchToIndex: index)
        }
    }
    
    /// 获取 pageCollectionView（用于手势排除）
    func getPageCollectionView() -> UICollectionView {
        return pageCollectionView
    }
    
    /// 获取所有已加载页面的水平滚动视图
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        var views: [UIScrollView] = [pageCollectionView]
        
        for (_, page) in loadedPages {
            views.append(contentsOf: page.getAllHorizontalScrollViews())
        }
        
        return views
    }
    
    /// 获取已缓存的页面
    func getCachedPage(at index: Int) -> AssetFlowPageProtocol? {
        return loadedPages[index]
    }
    
    // MARK: - Private Methods
    
    private func loadPage(at index: Int) -> AssetFlowPageProtocol? {
        if let page = loadedPages[index] {
            return page
        }
        
        guard let page = delegate?.assetFlowContainer(self, needsPageAt: index) else {
            return nil
        }
        
        loadedPages[index] = page
        return page
    }
    
    // MARK: - 页面生命周期通知
    
    private func notifyPageWillAppear(at index: Int) {
        loadedPages[index]?.pageWillAppear()
    }
    
    private func notifyPageDidAppear(at index: Int) {
        loadedPages[index]?.pageDidAppear()
    }
    
    private func notifyPageWillDisappear(at index: Int) {
        loadedPages[index]?.pageWillDisappear()
    }
    
    private func notifyPageDidDisappear(at index: Int) {
        loadedPages[index]?.pageDidDisappear()
    }
}

// MARK: - MenuViewDelegate
extension AssetFlowContainerView: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        scrollToPage(at: index, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension AssetFlowContainerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetFlowPageCell.reuseId, for: indexPath) as! AssetFlowPageCell
        
        let index = indexPath.item
        
        // cellForItemAt 只负责创建和配置 cell
        // 如果页面已加载，直接配置；否则配置空视图，等待 willDisplay 时加载
        if let page = loadedPages[index] {
            cell.configure(with: page.view)
        } else {
            // 先配置一个空视图占位，避免视觉闪烁
            // 实际的页面加载将在 willDisplay 中进行
            cell.configure(with: UIView())
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let index = indexPath.item
        
        // willDisplay 是 cell 真正要显示时调用，这是加载页面的合适时机
        // 根据文档建议，使用 willDisplay 来更新 cell 的视觉状态
        
        // 如果页面还未加载，则加载它
        if loadedPages[index] == nil {
            // 延迟加载优化：如果设置了初始索引且还未完成初始滚动
            // 在初始滚动完成前，只加载初始索引的页面，避免预加载其他页面
            let shouldLoad = hasPerformedInitialScroll || initialIndex == 0 || index == initialIndex
            
            if shouldLoad {
                if let page = loadPage(at: index),
                   let pageCell = cell as? AssetFlowPageCell {
                    pageCell.configure(with: page.view)
                }
            }
            // 如果 shouldLoad == false，说明是初始滚动前的非初始索引页面，不加载
        } else {
            // 页面已加载，确保 cell 配置正确
            if let page = loadedPages[index],
               let pageCell = cell as? AssetFlowPageCell {
                pageCell.configure(with: page.view)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension AssetFlowContainerView: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 手势拖拽开始，记录当前索引
        previousIndex = currentIndex
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        
        // 计算目标索引
        let targetIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        
        // 检测是否开始向新页面过渡
        if targetIndex != currentIndex && targetIndex >= 0 && targetIndex < pageCount && !isTransitioning {
            isTransitioning = true
            
            // 通知旧页面即将隐藏
            notifyPageWillDisappear(at: currentIndex)
            // 通知新页面即将显示
            notifyPageWillAppear(at: targetIndex)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollEnd(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        handleScrollEnd(scrollView)
    }
    
    private func handleScrollEnd(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        
        if index != previousIndex && index >= 0 && index < pageCount {
            // 页面确实发生了切换
            notifyPageDidDisappear(at: previousIndex)
            notifyPageDidAppear(at: index)
            
            currentIndex = index
            previousIndex = index
            menuView.selectItem(at: index)
            delegate?.assetFlowContainer(self, didSwitchToIndex: index)
        } else if isTransitioning {
            // 滑动取消，回到原页面
            notifyPageDidAppear(at: currentIndex)
            if previousIndex != currentIndex {
                notifyPageDidDisappear(at: previousIndex)
            }
        }
        
        isTransitioning = false
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetFlowContainerView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - AssetFlowPageCell
private class AssetFlowPageCell: UICollectionViewCell {
    static let reuseId = "AssetFlowPageCell"
    
    private var currentContentView: UIView?
    
    func configure(with contentView: UIView) {
        if currentContentView === contentView {
            return
        }
        
        currentContentView?.removeFromSuperview()
        currentContentView = contentView
        
        self.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
