import UIKit
import SnapKit

// MARK: - ================== 通用吸顶容器视图 ==================

/// 通用吸顶容器视图
/// 
/// 支持三个区域：
/// - Header 区域：可自定义的头部视图（滚动隐藏）
/// - Menu 区域：吸顶菜单（始终可见）
/// - Page 区域：分页内容容器
///
/// 特点：
/// - 业务无关，通过协议注入内容
/// - 内置嵌套滚动管理
/// - 支持吸顶效果
public class StickyHeaderContainerView: UIView, NestedScrollParentProtocol, NestedScrollContainerProtocol {
    
    // MARK: - NestedScrollParentProtocol
    
    public var canParentScroll: Bool = true
    
    public var headerHeight: CGFloat {
        // 返回实际需要滚动隐藏的高度（不含 stickyOffset，因为 stickyOffset 部分始终可见）
        let totalHeaderHeight = headerView?.bounds.height ?? 0
        return max(0, totalHeaderHeight - config.stickyOffset)
    }
    
    public var stickyOffset: CGFloat {
        return config.stickyOffset
    }
    
    public var parentScrollView: UIScrollView {
        return mainScrollView
    }
    
    // MARK: - NestedScrollContainerProtocol（约定大于配置）
    
    /// 注册可滚动的子视图（子视图通过响应链自动调用）
    public func registerScrollableChild(_ child: NestedScrollChildProtocol) {
        scrollManager.currentChild = child
    }
    
    /// 处理子视图滚动事件（子视图通过响应链自动调用）
    public func handleChildScroll(_ scrollView: UIScrollView) {
        scrollManager.handleChildScroll(scrollView)
    }
    
    // MARK: - Public Properties
    
    /// 数据源
    public weak var dataSource: StickyContainerDataSource? {
        didSet {
            if isConfigured {
                reloadData()
            }
        }
    }
    
    /// 代理
    public weak var delegate: StickyContainerDelegate?
    
    /// 配置
    public private(set) var config: StickyContainerConfig = StickyContainerConfig()
    
    /// 更新吸顶偏移量（当安全区域变化时调用）
    public func updateStickyOffset(_ newOffset: CGFloat) {
        guard newOffset != config.stickyOffset else { return }
        config.stickyOffset = newOffset
        setNeedsLayout()
    }
    
    /// 当前页面索引
    public private(set) var currentPageIndex: Int = 0
    
    /// 嵌套滚动管理器
    public private(set) var scrollManager = NestedScrollManager()
    
    /// 头部视图（外部设置）
    public var headerView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let header = headerView {
                contentView.insertSubview(header, at: 0)
                setupHeaderConstraints()
            }
        }
    }
    
    /// 菜单视图（外部设置或使用默认）
    public var menuView: StickyMenuViewProtocol? {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard config.menuEnabled else {
                // 菜单被禁用时，清理引用并确保布局不预留菜单空间
                if menuView != nil {
                    menuView = nil
                } else {
                    updatePageCollectionConstraintsForMenu()
                }
                return
            }
            
            if let menu = menuView {
                contentView.addSubview(menu)
                setupMenuConstraints()
                menu.onItemSelected = { [weak self] index in
                    self?.scrollToPage(at: index, animated: true)
                }
            } else {
                updatePageCollectionConstraintsForMenu()
            }
        }
    }
    
    /// 主滚动视图（暴露给外部使用）
    public var mainScrollView: NestedParentScrollView {
        return _mainScrollView
    }
    
    // MARK: - Private Properties
    
    private var isConfigured = false
    private var pageCount: Int = 0
    private var loadedPages: [Int: StickyPageProtocol] = [:]
    private var isFirstLayout = true
    private var previousPageIndex: Int = 0
    private var isTransitioning = false
    private var hasPerformedInitialScroll = false
    private var isMenuVisible: Bool {
        return config.menuEnabled && menuView != nil
    }
    
    private var headerHeightConstraint: Constraint?
    private var pageContainerHeightConstraint: Constraint?
    
    // MARK: - DiffableDataSource
    
    /// 分页 Section 枚举
    private enum PageSection: Hashable {
        case main
    }
    
    /// 分页 Item 模型
    private struct PageItem: Hashable {
        let index: Int
        let identifier: UUID  // 确保唯一性
        
        init(index: Int) {
            self.index = index
            self.identifier = UUID()
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
        }
        
        static func == (lhs: PageItem, rhs: PageItem) -> Bool {
            return lhs.index == rhs.index
        }
    }
    
    /// DiffableDataSource
    private var diffableDataSource: UICollectionViewDiffableDataSource<PageSection, PageItem>?
    
    // MARK: - UI Components
    
    private lazy var _mainScrollView: NestedParentScrollView = {
        let sv = NestedParentScrollView()
        sv.delegate = self
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    /// 分页容器 CollectionView
    private lazy var pageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.isPagingEnabled = true
        cv.bounces = false
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        // 使用 DiffableDataSource，不再设置 dataSource = self
        cv.register(StickyPageCell.self, forCellWithReuseIdentifier: StickyPageCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        cv.isPrefetchingEnabled = false
        return cv
    }()
    
    /// 页面容器视图（包含菜单和分页）
    private lazy var pageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    /// 配置容器
    /// - Parameters:
    ///   - config: 配置参数
    ///   - headerView: 头部视图
    ///   - menuView: 菜单视图（可选，config.menuEnabled = false 时忽略；nil 时默认提供内置菜单，也可在外部自行赋值）
    public func configure(
        with config: StickyContainerConfig,
        headerView: UIView,
        menuView: StickyMenuViewProtocol? = nil
    ) {
        self.config = config
        self.headerView = headerView
        
        // 仅在开启菜单时接入外部传入的菜单；可为 nil 以禁用菜单
        self.menuView = config.menuEnabled ? menuView : nil
        
        _mainScrollView.bounces = config.bounces
        currentPageIndex = config.initialPageIndex
        previousPageIndex = config.initialPageIndex
        
        isConfigured = true
        reloadData()
    }
    
    /// 重新加载数据
    public func reloadData() {
        guard isConfigured, let dataSource = dataSource else { return }
        
        pageCount = dataSource.numberOfPages(in: self)
        loadedPages.removeAll()
        hasPerformedInitialScroll = false
        
        // 确保索引在有效范围内
        let validIndex = max(0, min(config.initialPageIndex, pageCount > 0 ? pageCount - 1 : 0))
        currentPageIndex = validIndex
        previousPageIndex = validIndex
        
        // 菜单同步选中（若存在外部菜单）
        if isMenuVisible, pageCount > 0 {
            menuView?.selectItem(at: validIndex, animated: false)
        }
        
        // ⭐️ 使用 DiffableDataSource 的 snapshot 更新数据
        applySnapshot(animatingDifferences: false)
        
        // 滚动到初始位置
        if pageCount > 0 && validIndex > 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.pageCollectionView.layoutIfNeeded()
                
                let offsetX = CGFloat(validIndex) * self.pageCollectionView.bounds.width
                self.pageCollectionView.contentOffset = CGPoint(x: offsetX, y: 0)
                
                self.hasPerformedInitialScroll = true
                self.notifyPageWillAppear(at: validIndex)
                self.notifyPageDidAppear(at: validIndex)
                self.delegate?.stickyContainer(self, didSwitchToPageAt: validIndex)
            }
        } else {
            hasPerformedInitialScroll = true
            if pageCount > 0 {
                notifyPageWillAppear(at: 0)
                notifyPageDidAppear(at: 0)
            }
        }
        
        // 延迟更新 contentSize，确保布局完成
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.layoutIfNeeded()
            self.updateContentSize()
        }
    }
    
    /// 应用 snapshot 更新 CollectionView
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PageSection, PageItem>()
        snapshot.appendSections([.main])
        
        let items = (0..<pageCount).map { PageItem(index: $0) }
        snapshot.appendItems(items, toSection: .main)
        
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    /// 滚动到指定页面
    public func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < pageCount else { return }
        guard index != currentPageIndex else { return }
        
        notifyPageWillDisappear(at: currentPageIndex)
        notifyPageWillAppear(at: index)
        
        previousPageIndex = currentPageIndex
        currentPageIndex = index
        isTransitioning = animated
        
        pageCollectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
        menuView?.selectItem(at: index, animated: animated)
        
        if !animated {
            notifyPageDidDisappear(at: previousPageIndex)
            notifyPageDidAppear(at: index)
            delegate?.stickyContainer(self, didSwitchToPageAt: index)
        }
    }
    
    /// 获取 pageCollectionView（用于手势排除）
    public func getPageCollectionView() -> UICollectionView {
        return pageCollectionView
    }
    
    /// 获取所有已加载页面的水平滚动视图
    public func getAllHorizontalScrollViews() -> [UIScrollView] {
        var views: [UIScrollView] = [pageCollectionView]
        for (_, page) in loadedPages {
            views.append(contentsOf: page.getAllHorizontalScrollViews())
        }
        return views
    }
    
    /// 获取已缓存的页面
    public func getCachedPage(at index: Int) -> StickyPageProtocol? {
        return loadedPages[index]
    }
    
    /// 添加手势排除视图
    public func addGestureExcludeView(_ view: UIView) {
        _mainScrollView.addExcludeSuperView(view)
    }
    
    /// 更新手势排除（当页面内容变化时调用）
    public func updateGestureExclusion() {
        _mainScrollView.addExcludeSuperView(pageCollectionView)
        let allHorizontalViews = getAllHorizontalScrollViews()
        for view in allHorizontalViews {
            _mainScrollView.addExcludeSuperView(view)
        }
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateContentSize()
        
        if isFirstLayout && (headerView?.bounds.height ?? 0) > 0 {
            isFirstLayout = false
            DispatchQueue.main.async {
                self.updateGestureExclusion()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(_mainScrollView)
        _mainScrollView.addSubview(contentView)
        contentView.addSubview(pageContainerView)
        pageContainerView.addSubview(pageCollectionView)
        
        _mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        pageContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        pageCollectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        // 设置 scrollManager
        scrollManager.parentView = self
        
        // 配置 DiffableDataSource
        setupDiffableDataSource()
    }
    
    /// 配置 DiffableDataSource
    private func setupDiffableDataSource() {
        diffableDataSource = UICollectionViewDiffableDataSource<PageSection, PageItem>(
            collectionView: pageCollectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: StickyPageCell.reuseId,
                for: indexPath
            ) as! StickyPageCell
            
            let index = item.index
            
            // 配置 cell 内容
            if let page = self.loadedPages[index] {
                cell.configure(with: page.view)
            } else {
                cell.configure(with: UIView())
            }
            
            return cell
        }
    }
    
    private func setupHeaderConstraints() {
        guard let header = headerView else { return }
        
        header.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        pageContainerView.snp.remakeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupMenuConstraints() {
        guard let menu = menuView else { return }
        
        // 将菜单添加到 pageContainerView
        menu.removeFromSuperview()
        pageContainerView.addSubview(menu)
        
        menu.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(menu.menuHeight)
        }
        
        updatePageCollectionConstraintsForMenu()
    }
    
    private func updateContentSize() {
        let menuHeight = isMenuVisible ? (menuView?.menuHeight ?? config.menuHeight) : 0
        let contentHeight = bounds.height - config.stickyOffset - menuHeight
        
        if pageContainerHeightConstraint == nil {
            pageContainerView.snp.makeConstraints { make in
                pageContainerHeightConstraint = make.height.equalTo(contentHeight + menuHeight).constraint
            }
        } else {
            pageContainerHeightConstraint?.update(offset: contentHeight + menuHeight)
        }
        
        // 确保 headerView 布局完成
        headerView?.layoutIfNeeded()
        
        let headerH = headerView?.bounds.height ?? 0
        
        if pageCount == 0 || headerH == 0 {
            _mainScrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
            _mainScrollView.isScrollEnabled = pageCount > 0
        } else {
            // totalHeight = stickyOffset + headerHeight + menuHeight + contentHeight
            // 可滚动距离 = headerHeight（头部可以滚动隐藏的高度）
            let totalHeight = config.stickyOffset + headerH + menuHeight + contentHeight
            _mainScrollView.contentSize = CGSize(width: bounds.width, height: totalHeight)
            _mainScrollView.isScrollEnabled = true
        }
    }
    
    private func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // 使用实际需要滚动隐藏的高度（headerHeight 已经减去了 stickyOffset）
        let scrollableHeaderH = headerHeight
        
        // 计算滚动进度
        let progress = scrollableHeaderH > 0 ? min(1, max(0, offsetY / scrollableHeaderH)) : 0
        delegate?.stickyContainer(self, scrollProgressDidChange: progress)
        
        // 处理嵌套滚动
        scrollManager.handleParentScroll(scrollView)
        
        // 菜单吸顶
        if isMenuVisible {
            updateStickyMenuPosition(offsetY: min(offsetY, scrollableHeaderH))
        }
    }
    
    private func updateStickyMenuPosition(offsetY: CGFloat) {
        guard isMenuVisible, let menu = menuView else { return }
        // stickyPoint 是实际需要滚动隐藏的高度（不含 stickyOffset）
        let stickyPoint = headerHeight
        
        if offsetY >= stickyPoint {
            let transformY = offsetY - stickyPoint
            menu.transform = CGAffineTransform(translationX: 0, y: transformY)
        } else {
            menu.transform = .identity
        }
    }
    
    private func loadPage(at index: Int) -> StickyPageProtocol? {
        if let page = loadedPages[index] {
            return page
        }
        
        guard let dataSource = dataSource else { return nil }
        
        let page = dataSource.stickyContainer(self, pageAt: index)
        
        // 向后兼容：绑定滚动回调（推荐使用响应链方式，无需手动绑定）
        // 如果子页面使用响应链方式，这些闭包会被忽略
        page.setScrollCallbacks(
            onScroll: { [weak self] scrollView in
                self?.scrollManager.handleChildScroll(scrollView)
            },
            onChildChanged: { [weak self] child in
                self?.scrollManager.currentChild = child
            }
        )
        
        loadedPages[index] = page
        
        // 通知代理
        delegate?.stickyContainer(self, didLoadPageAt: index, page: page)
        
        // 更新手势排除
        DispatchQueue.main.async {
            self.updateGestureExclusion()
        }
        
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

// MARK: - UICollectionViewDelegate (willDisplay)
extension StickyHeaderContainerView {
    /// 当 Cell 即将显示时加载页面内容
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 只处理 pageCollectionView
        guard collectionView === pageCollectionView else { return }
        
        let index = indexPath.item
        
        if loadedPages[index] == nil {
            let shouldLoad = hasPerformedInitialScroll || config.initialPageIndex == 0 || index == config.initialPageIndex
            
            if shouldLoad {
                if let page = loadPage(at: index),
                   let pageCell = cell as? StickyPageCell {
                    pageCell.configure(with: page.view)
                }
            }
        } else {
            if let page = loadedPages[index],
               let pageCell = cell as? StickyPageCell {
                pageCell.configure(with: page.view)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate & UIScrollViewDelegate
extension StickyHeaderContainerView: UICollectionViewDelegate, UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === pageCollectionView {
            previousPageIndex = currentPageIndex
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 处理主滚动视图
        if scrollView === _mainScrollView {
            handleScroll(scrollView)
            return
        }
        
        // 处理分页 CollectionView
        guard scrollView === pageCollectionView else { return }
        guard scrollView.bounds.width > 0 else { return }
        
        let targetIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        
        if targetIndex != currentPageIndex && targetIndex >= 0 && targetIndex < pageCount && !isTransitioning {
            isTransitioning = true
            notifyPageWillDisappear(at: currentPageIndex)
            notifyPageWillAppear(at: targetIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === pageCollectionView {
            handlePageScrollEnd(scrollView)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView === pageCollectionView {
            handlePageScrollEnd(scrollView)
        }
    }
    
    private func handlePageScrollEnd(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        
        if index != previousPageIndex && index >= 0 && index < pageCount {
            notifyPageDidDisappear(at: previousPageIndex)
            notifyPageDidAppear(at: index)
            
            currentPageIndex = index
            previousPageIndex = index
            menuView?.selectItem(at: index, animated: true)
            delegate?.stickyContainer(self, didSwitchToPageAt: index)
            
            // 更新 currentChild
            if let page = loadedPages[index],
               let scrollChild = page.getCurrentScrollableChild() {
                scrollManager.currentChild = scrollChild
            }
        } else if isTransitioning {
            notifyPageDidAppear(at: currentPageIndex)
            if previousPageIndex != currentPageIndex {
                notifyPageDidDisappear(at: previousPageIndex)
            }
        }
        
        isTransitioning = false
        updateGestureExclusion()
    }
}

// MARK: - 布局辅助
private extension StickyHeaderContainerView {
    /// 根据当前菜单可见性更新分页区域约束
    func updatePageCollectionConstraintsForMenu() {
        pageCollectionView.snp.remakeConstraints { make in
            if isMenuVisible, let menu = menuView {
                make.top.equalTo(menu.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension StickyHeaderContainerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - StickyPageCell
private class StickyPageCell: UICollectionViewCell {
    static let reuseId = "StickyPageCell"
    
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

// MARK: - ================== 默认菜单视图已移除 ==================

