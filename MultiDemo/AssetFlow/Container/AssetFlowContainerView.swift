import UIKit

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
        return cv
    }()
    
    /// 菜单高度
    var menuHeight: CGFloat = 48 {
        didSet {
            menuHeightConstraint?.constant = menuHeight
        }
    }
    
    private var menuHeightConstraint: NSLayoutConstraint?
    
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
        
        menuView.translatesAutoresizingMaskIntoConstraints = false
        pageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        menuHeightConstraint = menuView.heightAnchor.constraint(equalToConstant: menuHeight)
        
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: topAnchor),
            menuView.leadingAnchor.constraint(equalTo: leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuHeightConstraint!,
            
            pageCollectionView.topAnchor.constraint(equalTo: menuView.bottomAnchor),
            pageCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        menuView.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 配置资产流（设置标题和数量，不立即创建页面）
    func configure(with titles: [String]) {
        self.titles = titles
        self.pageCount = titles.count
        self.currentIndex = 0
        self.previousIndex = 0
        self.loadedPages.removeAll()
        self.isTransitioning = false
        
        let menuItems = titles.map { MenuItem(title: $0) }
        menuView.configure(with: menuItems)
        
        pageCollectionView.reloadData()
        
        // 首次加载时，延迟通知第一个页面显示
        if pageCount > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.notifyPageWillAppear(at: 0)
                self?.notifyPageDidAppear(at: 0)
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
        
        if let page = loadPage(at: indexPath.item) {
            cell.configure(with: page.view)
        }
        
        return cell
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}
