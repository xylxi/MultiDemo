import UIKit

// MARK: - ================== 个人页面容器 ==================

/// 个人页面 ViewController
/// 职责：
/// 1. 展示用户信息头部（profileHeaderView）
/// 2. 提供资产流容器框架
/// 3. 处理嵌套滚动和吸顶效果
/// 
/// 资产流数据由外部通过 AssetFlowDataSource 注入
class ProfileViewController: UIViewController, NestedScrollParentProtocol {
    
    // MARK: - NestedScrollParentProtocol
    var canParentScroll: Bool = true
    
    var headerHeight: CGFloat {
        return profileHeaderView.bounds.height
    }
    
    var stickyOffset: CGFloat {
        return headerBarHeight
    }
    
    var parentScrollView: UIScrollView {
        return mainScrollView
    }
    
    // MARK: - Public Properties
    
    /// 资产流数据源（外部注入）
    weak var assetFlowDataSource: AssetFlowDataSource? {
        didSet {
            if isViewLoaded {
                reloadAssetFlows()
            }
        }
    }
    
    /// 资产流代理（外部注入）
    weak var assetFlowDelegate: AssetFlowDelegate?
    
    /// 嵌套滚动管理器（暴露给外部使用）
    private(set) var scrollManager = NestedScrollManager()
    
    // MARK: - Constants
    private let headerBarHeight: CGFloat = 88
    private let menuHeight: CGFloat = 48
    
    // MARK: - Private Properties
    private var assetFlowConfigs: [AssetFlowConfig] = []
    private var loadedPages: [Int: AssetFlowPageProtocol] = [:]
    private var containerHeightConstraint: NSLayoutConstraint?
    private var isFirstLayout = true
    
    // MARK: - UI Components
    
    /// 顶部导航栏
    private lazy var headerBar: ProfileHeaderBar = {
        let bar = ProfileHeaderBar()
        return bar
    }()
    
    /// 主滚动视图
    private lazy var mainScrollView: NestedParentScrollView = {
        let sv = NestedParentScrollView()
        sv.delegate = self
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    /// 用户信息头部（ProfileViewController 负责）
    private(set) lazy var profileHeaderView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        return view
    }()
    
    /// 资产流容器（包含菜单和分页）
    private lazy var assetFlowContainer: AssetFlowContainerView = {
        let container = AssetFlowContainerView()
        container.delegate = self
        container.scrollManager = scrollManager
        container.menuHeight = menuHeight
        return container
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScrollManager()
        reloadAssetFlows()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
        
        if isFirstLayout && profileHeaderView.bounds.height > 0 {
            isFirstLayout = false
            DispatchQueue.main.async {
                self.setupGestureExclusion()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 配置用户信息
    func configureProfile(_ profile: UserProfile) {
        profileHeaderView.configure(with: profile)
        headerBar.configure(title: profile.name)
    }
    
    /// 刷新资产流配置
    func reloadAssetFlows() {
        guard let dataSource = assetFlowDataSource else {
            assetFlowConfigs = []
            assetFlowContainer.configure(with: [])
            return
        }
        
        assetFlowConfigs = dataSource.assetFlowConfigs()
        loadedPages.removeAll()
        
        let titles = assetFlowConfigs.map { $0.title }
        assetFlowContainer.configure(with: titles)
    }
    
    /// 获取资产流菜单视图（用于自定义样式）
    var assetFlowMenuView: MenuView {
        return assetFlowContainer.menuView
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(contentView)
        
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor)
        ])
        
        // 用户信息头部
        contentView.addSubview(profileHeaderView)
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: headerBarHeight),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // 资产流容器
        contentView.addSubview(assetFlowContainer)
        assetFlowContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            assetFlowContainer.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor),
            assetFlowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            assetFlowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            assetFlowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // 顶部导航栏（最上层）
        view.addSubview(headerBar)
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: headerBarHeight)
        ])
    }
    
    private func setupScrollManager() {
        scrollManager.parentController = self
    }
    
    private func setupGestureExclusion() {
        // 添加资产流容器的水平滚动视图到排除列表
        mainScrollView.addExcludeSuperView(assetFlowContainer.getPageCollectionView())
        updateGestureExclusion()
    }
    
    private func updateGestureExclusion() {
        let allHorizontalViews = assetFlowContainer.getAllHorizontalScrollViews()
        for view in allHorizontalViews {
            mainScrollView.addExcludeSuperView(view)
        }
    }
    
    private func updateContentSize() {
        let contentHeight = view.bounds.height - headerBarHeight - menuHeight
        
        if containerHeightConstraint == nil {
            containerHeightConstraint = assetFlowContainer.heightAnchor.constraint(equalToConstant: contentHeight + menuHeight)
            containerHeightConstraint?.isActive = true
        } else {
            containerHeightConstraint?.constant = contentHeight + menuHeight
        }
        
        let totalHeight = headerBarHeight + profileHeaderView.bounds.height + menuHeight + contentHeight
        mainScrollView.contentSize = CGSize(width: view.bounds.width, height: totalHeight)
    }
    
    private func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        // HeaderBar 背景透明度
        let avatarBottomY = profileHeaderView.avatarBottomY + headerBarHeight
        let headerBarProgress = min(1, max(0, offsetY / avatarBottomY))
        headerBar.updateAppearance(progress: headerBarProgress)
        
        // 处理嵌套滚动
        scrollManager.handleParentScroll(scrollView)
        
        // 菜单吸顶
        updateStickyMenuPosition(offsetY: min(offsetY, profileHeaderView.bounds.height))
    }
    
    private func updateStickyMenuPosition(offsetY: CGFloat) {
        let stickyPoint = profileHeaderView.bounds.height
        
        if offsetY >= stickyPoint {
            assetFlowContainer.menuView.transform = CGAffineTransform(translationX: 0, y: offsetY - stickyPoint)
        } else {
            assetFlowContainer.menuView.transform = .identity
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ProfileViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === mainScrollView {
            handleScroll(scrollView)
        }
    }
}

// MARK: - AssetFlowContainerDelegate
extension ProfileViewController: AssetFlowContainerDelegate {
    func assetFlowContainer(_ container: AssetFlowContainerView, didSwitchToIndex index: Int) {
        // 更新手势排除
        updateGestureExclusion()
        
        // 更新 currentChild
        if let page = loadedPages[index],
           let scrollChild = page.getCurrentScrollableChild() {
            scrollManager.currentChild = scrollChild
        }
        
        // 通知代理
        if index < assetFlowConfigs.count {
            assetFlowDelegate?.assetFlowDidSwitchTo(index: index, title: assetFlowConfigs[index].title)
        }
    }
    
    func assetFlowContainer(_ container: AssetFlowContainerView, needsPageAt index: Int) -> AssetFlowPageProtocol? {
        guard index >= 0 && index < assetFlowConfigs.count else { return nil }
        
        // 检查缓存
        if let page = loadedPages[index] {
            return page
        }
        
        // 懒加载创建
        let page = assetFlowConfigs[index].pageFactory()
        page.setScrollManager(scrollManager)
        loadedPages[index] = page
        
        // 添加为子控制器
        addChild(page)
        page.didMove(toParent: self)
        
        // 更新手势排除
        DispatchQueue.main.async {
            self.updateGestureExclusion()
        }
        
        // 如果是当前页面，更新 currentChild
        if index == container.currentIndex,
           let scrollChild = page.getCurrentScrollableChild() {
            scrollManager.currentChild = scrollChild
        }
        
        // 通知代理
        assetFlowDelegate?.assetFlowDidLoadPage(at: index, page: page)
        
        print("[ProfileViewController] 懒加载资产流页面: \(assetFlowConfigs[index].title)")
        
        return page
    }
}

// MARK: - Preview
#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct ProfileViewController_Preview: PreviewProvider {
    static var previews: some View {
        ProfileViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

@available(iOS 13.0, *)
struct ProfileViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ProfileViewController {
        return ProfileViewController()
    }
    
    func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {}
}
#endif
