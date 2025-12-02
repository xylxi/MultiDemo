import UIKit
import SnapKit
import StickyScrollKit

// MARK: - ================== 个人页面容器 ==================

/// 个人页面 ViewController
/// 职责：
/// 1. 展示用户信息头部（profileHeaderView）
/// 2. 提供资产流容器框架
/// 3. 使用通用吸顶组件处理嵌套滚动和吸顶效果
/// 
/// 资产流数据由外部通过 AssetFlowDataSource 注入
class ProfileViewController: UIViewController {
    
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
    
    /// 默认定位的资产流索引（创建个人页面时指定，默认为 0）
    /// 
    /// 使用示例：
    /// ```swift
    /// let profileVC = ProfileViewController()
    /// // 默认定位到出境模块（索引 0）
    /// profileVC.defaultAssetFlowIndex = 0
    /// // 或默认定位到创作模块（索引 1）
    /// profileVC.defaultAssetFlowIndex = 1
    /// profileVC.assetFlowDataSource = dataSource
    /// ```
    /// 
    /// 注意：此属性应在设置 `assetFlowDataSource` 之前设置，或在 `reloadAssetFlows()` 之前设置
    var defaultAssetFlowIndex: Int = 1
    
    /// 嵌套滚动管理器（暴露给外部使用）
    var scrollManager: NestedScrollManager {
        return stickyContainer.scrollManager
    }
    
    // MARK: - Constants
    private let navBarContentHeight: CGFloat = 44  // 导航栏内容高度
    private let menuHeight: CGFloat = 48
    
    /// 导航栏总高度（安全区域 + 内容高度）
    private var headerBarHeight: CGFloat {
        return view.safeAreaInsets.top + navBarContentHeight
    }
    
    // MARK: - Private Properties
    private var assetFlowConfigs: [AssetFlowConfig] = []
    private var profileHeaderTopConstraint: Constraint?
    private var isFirstLayout = true
    
    // MARK: - UI Components
    
    /// 顶部导航栏
    private lazy var headerBar: ProfileHeaderBar = {
        let bar = ProfileHeaderBar()
        return bar
    }()
    
    /// 通用吸顶容器
    private lazy var stickyContainer: StickyHeaderContainerView = {
        let container = StickyHeaderContainerView()
        container.dataSource = self
        container.delegate = self
        return container
    }()
    
    /// 用户信息头部（ProfileViewController 负责）
    private(set) lazy var profileHeaderView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        return view
    }()
    
    /// 头部视图包装器（用于添加顶部间距）
    private lazy var headerWrapper: UIView = {
        let wrapper = UIView()
        wrapper.backgroundColor = .systemBackground
        wrapper.addSubview(profileHeaderView)
        
        // 初始约束（使用估计值，后续在 viewSafeAreaInsetsDidChange 中更新）
        let estimatedTopInset = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
        profileHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(estimatedTopInset + navBarContentHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        return wrapper
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadAssetFlows()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout && profileHeaderView.bounds.height > 0 {
            isFirstLayout = false
            updateHeaderWrapperLayout()
        }
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHeaderWrapperLayout()
        
        // 更新 stickyOffset（安全区域变化后才能获取正确的值）
        stickyContainer.updateStickyOffset(headerBarHeight)
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
            configureStickyContainer()
            return
        }
        
        assetFlowConfigs = dataSource.assetFlowConfigs()
        configureStickyContainer()
    }
    
    /// 获取资产流菜单视图（用于自定义样式）
    var assetFlowMenuView: StickyMenuViewProtocol? {
        return stickyContainer.menuView
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(stickyContainer)
        
        stickyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 顶部导航栏（最上层）
        view.addSubview(headerBar)
        
        headerBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            // 高度 = 安全区域顶部 + 导航栏内容高度
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(navBarContentHeight)
        }
    }
    
    private func configureStickyContainer() {
        // 先访问 headerWrapper 触发懒加载，确保 profileHeaderView 有 superview
        _ = headerWrapper
        
        // 更新头部视图顶部约束
        profileHeaderView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(headerBarHeight)
        }
        
        let config = StickyContainerConfig(
            menuHeight: menuHeight,
            stickyOffset: headerBarHeight,
            initialPageIndex: max(0, min(defaultAssetFlowIndex, assetFlowConfigs.count - 1)),
            bounces: true
        )
        
        stickyContainer.configure(
            with: config,
            headerView: headerWrapper,
            menuView: nil  // 使用默认菜单
        )
    }
    
    private func updateHeaderWrapperLayout() {
        profileHeaderView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(headerBarHeight)
        }
        headerWrapper.layoutIfNeeded()
    }
}

// MARK: - StickyContainerDataSource
extension ProfileViewController: StickyContainerDataSource {
    func numberOfPages(in container: StickyHeaderContainerView) -> Int {
        return assetFlowConfigs.count
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, titleForPageAt index: Int) -> String {
        guard index < assetFlowConfigs.count else { return "" }
        return assetFlowConfigs[index].title
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, pageAt index: Int) -> StickyPageProtocol {
        let page = assetFlowConfigs[index].pageFactory()
        
        // 添加为子控制器
        addChild(page)
        page.didMove(toParent: self)
        
        print("[ProfileViewController] 懒加载资产流页面: \(assetFlowConfigs[index].title)")
        
        return page
    }
}

// MARK: - StickyContainerDelegate
extension ProfileViewController: StickyContainerDelegate {
    func stickyContainer(_ container: StickyHeaderContainerView, didSwitchToPageAt index: Int) {
        // 通知代理
        if index < assetFlowConfigs.count {
            assetFlowDelegate?.assetFlowDidSwitchTo(index: index, title: assetFlowConfigs[index].title)
        }
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, scrollProgressDidChange progress: CGFloat) {
        // 更新 HeaderBar 背景透明度
        let avatarBottomY = profileHeaderView.avatarBottomY + headerBarHeight
        let headerH = profileHeaderView.bounds.height
        
        // 基于头像位置计算进度
        let currentOffset = progress * headerH
        let headerBarProgress = min(1, max(0, currentOffset / avatarBottomY))
        headerBar.updateAppearance(progress: headerBarProgress)
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, didLoadPageAt index: Int, page: StickyPageProtocol) {
        // 通知代理
        if let assetFlowPage = page as? AssetFlowPageProtocol {
            assetFlowDelegate?.assetFlowDidLoadPage(at: index, page: assetFlowPage)
        }
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
