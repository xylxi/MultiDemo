import UIKit
import SnapKit

// MARK: - ================== 互动模块 ==================
// 负责人：开发者 C
// 此模块直接展示内容，没有子模块

/// 互动模块 ViewController
/// 实现 AssetFlowPageProtocol 和 NestedScrollChildProtocol 协议
/// 
/// 解耦设计：不依赖 NestedScrollManager 和 WorksFlowViewController，独立实现
class InteractionViewController: UIViewController, AssetFlowPageProtocol, NestedScrollChildProtocol {
    
    // MARK: - AssetFlowPageProtocol
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        return self // 自己是叶子节点
    }
    
    func setScrollCallbacks(onScroll: @escaping ScrollEventHandler,
                            onChildChanged: @escaping CurrentChildChangedHandler) {
        self.onScrollEvent = onScroll
        self.onCurrentChildChanged = onChildChanged
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [] // 没有水平滚动的 CollectionView
    }
    
    // MARK: - NestedScrollChildProtocol
    
    var childScrollView: UIScrollView {
        return collectionView
    }
    
    var canChildScroll: Bool = false
    
    // MARK: - 闭包回调（解耦 NestedScrollManager）
    private var onScrollEvent: ScrollEventHandler?
    private var onCurrentChildChanged: CurrentChildChangedHandler?
    
    // MARK: - Properties
    private let moduleName = "互动"
    private let moduleColor = UIColor.systemPurple // 使用紫色作为互动模块的颜色
    
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
        cv.register(InteractionCell.self, forCellWithReuseIdentifier: InteractionCell.reuseId)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsVerticalScrollIndicator = true
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("[InteractionViewController] viewDidLoad - 互动模块已加载")
    }
    
    // MARK: - 页面生命周期
    func pageWillAppear() {
        print("[InteractionViewController] pageWillAppear - 互动页面即将显示")
    }
    
    func pageDidAppear() {
        print("[InteractionViewController] pageDidAppear - 互动页面已显示")
        // 通知父容器当前子视图已变更
        onCurrentChildChanged?(self)
    }
    
    func pageWillDisappear() {
        print("[InteractionViewController] pageWillDisappear - 互动页面即将隐藏")
    }
    
    func pageDidDisappear() {
        print("[InteractionViewController] pageDidDisappear - 互动页面已隐藏")
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
extension InteractionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 60 // Mock 60 个互动内容，确保可以滚动
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InteractionCell.reuseId, for: indexPath) as! InteractionCell
        // 使用模块名称+index+颜色的格式
        cell.configure(title: "\(moduleName)\n#\(indexPath.item + 1)", color: moduleColor)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension InteractionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScrollEvent?(scrollView)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension InteractionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 2
        let sectionInset: CGFloat = 2
        let totalSpacing = spacing * 2 + sectionInset * 2
        let width = (collectionView.bounds.width - totalSpacing) / 3
        return CGSize(width: width, height: width * 1.3)
    }
}

// MARK: - InteractionCell
private class InteractionCell: UICollectionViewCell {
    static let reuseId = "InteractionCell"
    
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

