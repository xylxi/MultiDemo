import UIKit

// MARK: - 菜单项协议
protocol MenuItemProtocol {
    var title: String { get }
    var hasChildren: Bool { get }
}

struct MenuItem: MenuItemProtocol {
    let title: String
    let hasChildren: Bool
    
    init(title: String, hasChildren: Bool = false) {
        self.title = title
        self.hasChildren = hasChildren
    }
}

// MARK: - 菜单视图代理
protocol MenuViewDelegate: AnyObject {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int)
}

// MARK: - 菜单视图
class MenuView: UIView {
    
    weak var delegate: MenuViewDelegate?
    
    private var items: [MenuItemProtocol] = []
    private var selectedIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(MenuCell.self, forCellWithReuseIdentifier: MenuCell.reuseId)
        return cv
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    private let indicatorHeight: CGFloat = 3
    private var indicatorWidthConstraint: NSLayoutConstraint?
    private var indicatorCenterXConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(collectionView)
        addSubview(indicatorView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -indicatorHeight),
            
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorHeight)
        ])
        
        indicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: 30)
        indicatorCenterXConstraint = indicatorView.centerXAnchor.constraint(equalTo: leadingAnchor)
        
        indicatorWidthConstraint?.isActive = true
        indicatorCenterXConstraint?.isActive = true
    }
    
    func configure(with items: [MenuItemProtocol], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = selectedIndex
        collectionView.reloadData()
        
        DispatchQueue.main.async {
            self.updateIndicator(animated: false)
        }
    }
    
    func selectItem(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selectedIndex = index
        collectionView.reloadData()
        updateIndicator(animated: animated)
    }
    
    private func updateIndicator(animated: Bool) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) else {
            return
        }
        
        let cellFrame = cell.frame
        let centerX = cellFrame.midX
        let width = min(cellFrame.width - 20, 40)
        
        indicatorCenterXConstraint?.constant = centerX
        indicatorWidthConstraint?.constant = width
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension MenuView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCell.reuseId, for: indexPath) as! MenuCell
        let item = items[indexPath.item]
        cell.configure(title: item.title, isSelected: indexPath.item == selectedIndex)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MenuView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItem(at: indexPath.item)
        delegate?.menuView(self, didSelectItemAt: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MenuView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = items[indexPath.item].title
        let width = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]).width + 32
        return CGSize(width: width, height: collectionView.bounds.height)
    }
}

// MARK: - MenuCell
class MenuCell: UICollectionViewCell {
    static let reuseId = "MenuCell"
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
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
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .systemBlue : .darkGray
        titleLabel.font = isSelected ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 16, weight: .medium)
    }
}
