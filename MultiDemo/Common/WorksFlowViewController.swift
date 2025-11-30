import UIKit
import SnapKit

// MARK: - ================== 作品流 ==================

/// 作品流 ViewController（叶子节点）
/// 展示具体的作品列表
/// 
/// 解耦设计：不依赖 NestedScrollManager，通过闭包回调处理滚动事件
class WorksFlowViewController: UIViewController, NestedScrollChildProtocol {
    
    // MARK: - NestedScrollChildProtocol
    var childScrollView: UIScrollView { collectionView }
    var canChildScroll: Bool = false
    
    // MARK: - 闭包回调（解耦 NestedScrollManager）
    
    /// 滚动事件回调，由外部处理滚动逻辑
    var onScrollEvent: ((UIScrollView) -> Void)?
    
    // MARK: - Properties
    private let categoryPath: String
    private let color: UIColor
    
    // MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(WorksCell.self, forCellWithReuseIdentifier: WorksCell.reuseId)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsVerticalScrollIndicator = true
        return cv
    }()
    
    // MARK: - Init
    init(categoryPath: String, color: UIColor) {
        self.categoryPath = categoryPath
        self.color = color
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("[WorksFlowViewController] viewDidLoad - \(categoryPath)")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension WorksFlowViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 60 // Mock 60 个作品，确保可以滚动
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WorksCell.reuseId, for: indexPath) as! WorksCell
        cell.configure(title: "\(categoryPath)\n#\(indexPath.item + 1)", color: color)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension WorksFlowViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScrollEvent?(scrollView)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension WorksFlowViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 2
        let sectionInset: CGFloat = 2
        let totalSpacing = spacing * 2 + sectionInset * 2
        let width = (collectionView.bounds.width - totalSpacing) / 3
        return CGSize(width: width, height: width * 1.3)
    }
}

// MARK: - WorksCell
class WorksCell: UICollectionViewCell {
    static let reuseId = "WorksCell"
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
        }
    }
    
    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        containerView.backgroundColor = color
    }
}
