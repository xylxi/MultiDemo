import UIKit

// MARK: - 分页容器代理
protocol PageContainerDelegate: AnyObject {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int)
}

// MARK: - 分页容器 ViewController
class PageContainerViewController: UIViewController {
    
    weak var delegate: PageContainerDelegate?
    weak var scrollManager: NestedScrollManager?
    
    private(set) var currentIndex: Int = 0
    private var childControllers: [UIViewController] = []
    
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
    
    func configure(with controllers: [UIViewController]) {
        // 移除旧的子控制器
        childControllers.forEach { child in
            child.willMove(toParent: nil)
            child.removeFromParent()
        }
        
        childControllers = controllers
        
        // 添加新的子控制器
        controllers.forEach { child in
            addChild(child)
            child.didMove(toParent: self)
        }
        
        collectionView.reloadData()
    }
    
    func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < childControllers.count else { return }
        currentIndex = index
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        
        if !animated {
            delegate?.pageContainer(self, didScrollToIndex: index)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension PageContainerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childControllers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageContainerCell.reuseId, for: indexPath) as! PageContainerCell
        cell.configure(with: childControllers[indexPath.item].view)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension PageContainerViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex && index >= 0 && index < childControllers.count {
            currentIndex = index
            delegate?.pageContainer(self, didScrollToIndex: index)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index >= 0 && index < childControllers.count {
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
        // 不移除 contentView，因为它被 ViewController 持有
    }
    
    func configure(with contentView: UIView) {
        // 如果已经是同一个 view，不需要重新添加
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
