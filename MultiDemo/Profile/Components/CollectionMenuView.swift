import UIKit
import SnapKit
import StickyScrollKit

/// 使用 UICollectionView 实现的自定义菜单视图，选中项有放大效果
final class CollectionMenuView: UIView, StickyMenuViewProtocol {
    
    // MARK: - StickyMenuViewProtocol
    var menuHeight: CGFloat = 48 {
        didSet {
            snp.updateConstraints { make in
                make.height.equalTo(menuHeight)
            }
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    var onItemSelected: ((Int) -> Void)?
    
    // MARK: - Private
    private var titles: [String] = []
    private var selectedIndex: Int = 0
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(CollectionMenuCell.self, forCellWithReuseIdentifier: CollectionMenuCell.reuseId)
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 配置标题列表
    func configure(titles: [String]) {
        self.titles = titles
        collectionView.reloadData()
        if !titles.isEmpty {
            selectItem(at: 0, animated: false)
        }
    }
    
    func selectItem(at index: Int, animated: Bool) {
        guard index >= 0, index < titles.count else { return }
        selectedIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        collectionView.visibleCells.compactMap { $0 as? CollectionMenuCell }.forEach { cell in
            cell.updateSelection(animated: animated)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension CollectionMenuView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionMenuCell.reuseId, for: indexPath) as! CollectionMenuCell
        cell.configure(title: titles[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CollectionMenuView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        onItemSelected?(indexPath.item)
        collectionView.visibleCells.compactMap { $0 as? CollectionMenuCell }.forEach { cell in
            cell.updateSelection(animated: true)
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CollectionMenuView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = titles[indexPath.item]
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        let width = (title as NSString).size(withAttributes: [.font: font]).width + 24
        return CGSize(width: max(60, width), height: menuHeight - 12)
    }
}

// MARK: - Cell
private final class CollectionMenuCell: UICollectionViewCell {
    static let reuseId = "CollectionMenuCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            updateSelection(animated: true)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String) {
        titleLabel.text = title
        updateSelection(animated: false)
    }
    
    func updateSelection(animated: Bool) {
        let scale: CGFloat = isSelected ? 1.12 : 1.0
        let color: UIColor = isSelected ? .label : .secondaryLabel
        let font: UIFont = isSelected ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 16, weight: .medium)
        
        let animations = {
            self.titleLabel.textColor = color
            self.titleLabel.font = font
            self.contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: animations)
        } else {
            animations()
        }
    }
}
