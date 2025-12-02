import UIKit
import SnapKit
import StickyScrollKit

// MARK: - ================== 出境模块 ==================
// 负责人：开发者 A
// 此文件展示如何实现一个资产流模块

/// 出境模块 ViewController
/// 实现 AssetFlowPageProtocol 协议
/// 
/// 解耦设计：
/// - 使用"约定大于配置"原则
/// - 子页面（WorksFlowViewController）通过响应链自动发现容器
/// - 无需手动传递闭包
class AppearanceViewController: UIViewController, AssetFlowPageProtocol {
    
    // MARK: - AssetFlowPageProtocol
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        // 如果当前页面还没加载，先加载它
        if currentWorksFlowVC == nil && loadedPages[currentIndex] == nil {
            _ = loadPage(at: currentIndex)
        }
        return currentWorksFlowVC
    }
    
    func setScrollCallbacks(onScroll: @escaping (UIScrollView) -> Void,
                            onChildChanged: @escaping (NestedScrollChildProtocol) -> Void) {
        // 约定大于配置：不再需要手动绑定闭包
        // 子页面通过响应链自动发现容器
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [pageCollectionView]
    }
    
    // MARK: - Properties
    private var currentWorksFlowVC: WorksFlowViewController?
    private var loadedPages: [Int: WorksFlowViewController] = [:]
    
    // MARK: - 子分类配置
    private let subCategories: [(title: String, color: UIColor)] = [
        ("作品", .systemBlue),
        ("喜欢", UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1)), // iOS 13 兼容
        ("点赞", .systemTeal)
    ]
    
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
    
    private var currentIndex: Int = 0
    
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
        let menuItems = subCategories.map { MenuItem(title: $0.title) }
        menuView.configure(with: menuItems)
    }
    
    private func loadPage(at index: Int) -> WorksFlowViewController {
        if let page = loadedPages[index] {
            return page
        }
        
        let category = subCategories[index]
        let path = "出境 > \(category.title)"
        let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
        
        // ✅ 不再需要手动绑定闭包
        // worksVC 会在 viewDidAppear 时通过响应链自动发现容器
        
        addChild(worksVC)
        worksVC.didMove(toParent: self)
        
        loadedPages[index] = worksVC
        
        if index == currentIndex {
            currentWorksFlowVC = worksVC
        }
        
        return worksVC
    }
}

// MARK: - MenuViewDelegate
extension AppearanceViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        currentIndex = index
        pageCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension AppearanceViewController: UICollectionViewDataSource {
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

// MARK: - UICollectionViewDelegate
extension AppearanceViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndex(from: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentIndex(from: scrollView)
    }
    
    private func updateCurrentIndex(from scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex && index >= 0 && index < subCategories.count {
            currentIndex = index
            menuView.selectItem(at: index)
            
            if let worksVC = loadedPages[index] {
                currentWorksFlowVC = worksVC
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AppearanceViewController: UICollectionViewDelegateFlowLayout {
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
