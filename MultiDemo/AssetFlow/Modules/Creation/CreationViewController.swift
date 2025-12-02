import UIKit
import SnapKit

// MARK: - ================== 创作模块 ==================
// 负责人：开发者 B
// 此模块包含三级分类（创作 > 资产 > 全部/图片/视频/收藏）

/// 创作模块 ViewController
/// 
/// 解耦设计：
/// - 使用"约定大于配置"原则
/// - 子页面（WorksFlowViewController）通过响应链自动发现容器
/// - 无需手动传递闭包
class CreationViewController: UIViewController, AssetFlowPageProtocol {
    
    // MARK: - AssetFlowPageProtocol
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        // 需要递归获取当前激活的子视图
        // 如果当前页面还没加载，先加载它
        if loadedPages[currentIndex] == nil {
            _ = loadPage(at: currentIndex)
        }
        
        let currentPage = loadedPages[currentIndex]
        
        if let assetsVC = currentPage as? AssetsViewController {
            return assetsVC.getCurrentScrollableChild()
        } else if let worksVC = currentPage as? WorksFlowViewController {
            return worksVC
        }
        return nil
    }
    
    func setScrollCallbacks(onScroll: @escaping (UIScrollView) -> Void,
                            onChildChanged: @escaping (NestedScrollChildProtocol) -> Void) {
        // 约定大于配置：不再需要手动绑定闭包
        // 子页面通过响应链自动发现容器
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        var views: [UIScrollView] = [pageCollectionView]
        
        for (_, page) in loadedPages {
            if let assetsVC = page as? AssetsViewController {
                views.append(contentsOf: assetsVC.getAllHorizontalScrollViews())
            }
        }
        
        return views
    }
    
    // MARK: - Properties
    private var loadedPages: [Int: UIViewController] = [:]
    private var currentIndex: Int = 0
    
    // MARK: - 子分类配置
    private enum SubCategory: Int, CaseIterable {
        case publish = 0
        case assets
        case like
        
        var title: String {
            switch self {
            case .publish: return "发布"
            case .assets: return "资产"
            case .like: return "喜欢"
            }
        }
        
        var color: UIColor {
            switch self {
            case .publish: return .systemPink
            case .assets: return .systemOrange
            case .like: return .systemIndigo
            }
        }
        
        var hasSubCategories: Bool {
            return self == .assets
        }
    }
    
    // MARK: - UI
    private lazy var menuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        return menu
    }()
    
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
        cv.register(PageCell.self, forCellWithReuseIdentifier: PageCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenu()
    }
    
    // MARK: - 页面生命周期
    func pageWillAppear() { }
    func pageDidAppear() { }
    func pageWillDisappear() { }
    func pageDidDisappear() { }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(menuView)
        view.addSubview(pageCollectionView)
        
        menuView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        pageCollectionView.snp.makeConstraints { make in
            make.top.equalTo(menuView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupMenu() {
        let menuItems = SubCategory.allCases.map { MenuItem(title: $0.title, hasChildren: $0.hasSubCategories) }
        menuView.configure(with: menuItems)
    }
    
    private func loadPage(at index: Int) -> UIViewController {
        if let page = loadedPages[index] {
            return page
        }
        
        guard let category = SubCategory(rawValue: index) else {
            fatalError("Invalid category index")
        }
        
        let page: UIViewController
        
        if category == .assets {
            // 资产有三级分类
            let assetsVC = AssetsViewController()
            // ✅ 不再需要手动绑定闭包
            page = assetsVC
        } else {
            let path = "创作 > \(category.title)"
            let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
            // ✅ 不再需要手动绑定闭包
            // worksVC 会在 viewDidAppear 时通过响应链自动发现容器
            page = worksVC
        }
        
        addChild(page)
        page.didMove(toParent: self)
        
        loadedPages[index] = page
        
        return page
    }
}

// MARK: - MenuViewDelegate
extension CreationViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        currentIndex = index
        pageCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension CreationViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SubCategory.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageCell.reuseId, for: indexPath) as! PageCell
        let page = loadPage(at: indexPath.item)
        cell.configure(with: page.view)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CreationViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndexFromScroll(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentIndexFromScroll(scrollView)
    }
    
    private func updateCurrentIndexFromScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex && index >= 0 && index < SubCategory.allCases.count {
            currentIndex = index
            menuView.selectItem(at: index)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CreationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - ================== 资产模块（三级分类） ==================

/// 资产 ViewController
/// 创作模块的子模块，包含四个子分类
/// 
/// 解耦设计：
/// - 使用"约定大于配置"原则
/// - 子页面通过响应链自动发现容器
class AssetsViewController: UIViewController {
    
    private var loadedPages: [Int: WorksFlowViewController] = [:]
    private var currentIndex: Int = 0
    
    // 资产子分类
    private let subCategories: [(title: String, color: UIColor)] = [
        ("全部", .systemOrange),
        ("图片", .systemYellow),
        ("视频", .systemGreen),
        ("收藏", UIColor(red: 0.0, green: 0.78, blue: 0.74, alpha: 1)) // iOS 13 兼容
    ]
    
    private lazy var menuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        return menu
    }()
    
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
        cv.register(PageCell.self, forCellWithReuseIdentifier: PageCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenu()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(menuView)
        view.addSubview(pageCollectionView)
        
        menuView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        pageCollectionView.snp.makeConstraints { make in
            make.top.equalTo(menuView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupMenu() {
        let menuItems = subCategories.map { MenuItem(title: $0.title) }
        menuView.configure(with: menuItems)
    }
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        // 如果当前页面还没加载，先加载它
        if loadedPages[currentIndex] == nil {
            _ = loadPage(at: currentIndex)
        }
        return loadedPages[currentIndex]
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [pageCollectionView]
    }
    
    private func loadPage(at index: Int) -> WorksFlowViewController {
        if let page = loadedPages[index] {
            return page
        }
        
        let category = subCategories[index]
        let path = "创作 > 资产 > \(category.title)"
        let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
        
        // ✅ 不再需要手动绑定闭包
        // worksVC 会在 viewDidAppear 时通过响应链自动发现容器
        
        addChild(worksVC)
        worksVC.didMove(toParent: self)
        
        loadedPages[index] = worksVC
        
        return worksVC
    }
}

// MARK: - AssetsViewController + MenuViewDelegate
extension AssetsViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        currentIndex = index
        pageCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - AssetsViewController + UICollectionViewDataSource
extension AssetsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageCell.reuseId, for: indexPath) as! PageCell
        let page = loadPage(at: indexPath.item)
        cell.configure(with: page.view)
        return cell
    }
}

// MARK: - AssetsViewController + UICollectionViewDelegate
extension AssetsViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndex(from: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateIndex(from: scrollView)
    }
    
    private func updateIndex(from scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex && index >= 0 && index < subCategories.count {
            currentIndex = index
            menuView.selectItem(at: index)
        }
    }
}

// MARK: - AssetsViewController + UICollectionViewDelegateFlowLayout
extension AssetsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - PageCell
private class PageCell: UICollectionViewCell {
    static let reuseId = "PageCell"
    
    private var currentContentView: UIView?
    
    func configure(with contentView: UIView) {
        if currentContentView === contentView { return }
        
        currentContentView?.removeFromSuperview()
        currentContentView = contentView
        
        self.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
