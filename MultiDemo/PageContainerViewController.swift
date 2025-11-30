import UIKit

// MARK: - 分页容器代理
protocol PageContainerDelegate: AnyObject {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int)
    func pageContainer(_ container: PageContainerViewController, needsPageAt index: Int) -> UIViewController?
}

// MARK: - 分页容器 ViewController（支持懒加载）
class PageContainerViewController: UIViewController {
    
    weak var delegate: PageContainerDelegate?
    weak var scrollManager: NestedScrollManager?
    
    private(set) var currentIndex: Int = 0
    private(set) var pageCount: Int = 0
    
    /// 已加载的页面缓存
    private var loadedPages: [Int: UIViewController] = [:]
    
    /// 暴露 collectionView 用于手势排除
    var pageCollectionView: UICollectionView {
        return collectionView
    }
    
    private lazy var collectionView: UICollectionView = {
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
        cv.register(PageContainerCell.self, forCellWithReuseIdentifier: PageContainerCell.reuseId)
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// 设置页面数量（不立即创建页面）
    func setPageCount(_ count: Int) {
        self.pageCount = count
        self.loadedPages.removeAll()
        collectionView.reloadData()
    }
    
    func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < pageCount else { return }
        currentIndex = index
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        
        if !animated {
            delegate?.pageContainer(self, didScrollToIndex: index)
        }
    }
    
    /// 获取指定索引的页面（触发懒加载）
    private func loadPage(at index: Int) -> UIViewController? {
        // 已加载则直接返回
        if let page = loadedPages[index] {
            return page
        }
        
        // 通过代理获取页面（懒加载）
        guard let page = delegate?.pageContainer(self, needsPageAt: index) else {
            return nil
        }
        
        // 添加为子控制器
        addChild(page)
        page.didMove(toParent: self)
        
        // 缓存
        loadedPages[index] = page
        
        return page
    }
    
    /// 获取所有已加载的 PageCollectionView（用于手势排除）
    func getAllPageCollectionViews() -> [UICollectionView] {
        var views = [collectionView]
        
        for (_, page) in loadedPages {
            if let categoryPage = page as? CategoryPageProtocol,
               let child = categoryPage.getCurrentScrollChild() as? UIViewController,
               let pageContainer = findPageContainer(in: child) {
                views.append(contentsOf: pageContainer.getAllPageCollectionViews())
            }
            // 递归查找嵌套的 PageContainerViewController
            if let nestedContainers = findAllPageContainers(in: page) {
                for container in nestedContainers {
                    views.append(container.pageCollectionView)
                }
            }
        }
        
        return views
    }
    
    private func findPageContainer(in viewController: UIViewController) -> PageContainerViewController? {
        if let container = viewController as? PageContainerViewController {
            return container
        }
        for child in viewController.children {
            if let found = findPageContainer(in: child) {
                return found
            }
        }
        return nil
    }
    
    private func findAllPageContainers(in viewController: UIViewController) -> [PageContainerViewController]? {
        var containers: [PageContainerViewController] = []
        
        for child in viewController.children {
            if let container = child as? PageContainerViewController {
                containers.append(container)
                if let nested = findAllPageContainers(in: container) {
                    containers.append(contentsOf: nested)
                }
            } else if let nested = findAllPageContainers(in: child) {
                containers.append(contentsOf: nested)
            }
        }
        
        return containers.isEmpty ? nil : containers
    }
}

// MARK: - UICollectionViewDataSource
extension PageContainerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageContainerCell.reuseId, for: indexPath) as! PageContainerCell
        
        // 懒加载页面
        if let page = loadPage(at: indexPath.item) {
            cell.configure(with: page.view)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension PageContainerViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndex(from: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentIndex(from: scrollView)
    }
    
    private func updateCurrentIndex(from scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex && index >= 0 && index < pageCount {
            currentIndex = index
            delegate?.pageContainer(self, didScrollToIndex: index)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PageContainerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - PageContainerCell
class PageContainerCell: UICollectionViewCell {
    static let reuseId = "PageContainerCell"
    
    private var currentContentView: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
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
