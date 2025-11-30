import UIKit

// MARK: - ProfileViewController（容器页面）
/// 个人页面容器，负责：
/// 1. 展示用户信息头部
/// 2. 管理一级分类（出境、创作等）
/// 3. 懒加载各个分类模块
/// 4. 处理嵌套滚动和吸顶效果
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
    
    // MARK: - Constants
    private let headerBarHeight: CGFloat = 88
    private let menuHeight: CGFloat = 48
    
    // MARK: - Properties
    private let scrollManager = NestedScrollManager()
    private let pageManager = CategoryPageManager()
    private var containerHeightConstraint: NSLayoutConstraint?
    private var isFirstLayout = true
    
    // MARK: - UI Components
    private lazy var headerBar: ProfileHeaderBar = {
        let bar = ProfileHeaderBar()
        bar.configure(title: mockProfile.name)
        return bar
    }()
    
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
    
    private lazy var profileHeaderView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        view.configure(with: mockProfile)
        return view
    }()
    
    private lazy var stickyMenuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        menu.backgroundColor = .systemBackground
        return menu
    }()
    
    private lazy var pageContainer: PageContainerViewController = {
        let pc = PageContainerViewController()
        pc.delegate = self
        pc.scrollManager = scrollManager
        return pc
    }()
    
    // MARK: - Mock Data
    private let mockProfile = UserProfile(
        avatar: "",
        name: "创作者小明",
        userId: "xiaoming_2024",
        bio: "热爱生活，热爱创作 ✨ 每天分享有趣的内容",
        followingCount: 256,
        followersCount: 12580,
        likesCount: 98700
    )
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScrollManager()
        setupCategoryPages()
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
    
    // MARK: - Setup
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
        
        contentView.addSubview(profileHeaderView)
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: headerBarHeight),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        contentView.addSubview(stickyMenuView)
        stickyMenuView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickyMenuView.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor),
            stickyMenuView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stickyMenuView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stickyMenuView.heightAnchor.constraint(equalToConstant: menuHeight)
        ])
        
        addChild(pageContainer)
        contentView.addSubview(pageContainer.view)
        pageContainer.didMove(toParent: self)
        
        pageContainer.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageContainer.view.topAnchor.constraint(equalTo: stickyMenuView.bottomAnchor),
            pageContainer.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageContainer.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageContainer.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
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
    
    /// 配置一级分类页面（懒加载）
    private func setupCategoryPages() {
        // 配置各个分类模块（由不同开发者负责）
        let configs: [CategoryPageConfig] = [
            // 出境模块 - 开发者 A 负责
            CategoryPageConfig(title: "出境") { [weak self] in
                let vc = AppearanceViewController()
                vc.setScrollManager(self?.scrollManager)
                return vc
            },
            // 创作模块 - 开发者 B 负责
            CategoryPageConfig(title: "创作") { [weak self] in
                let vc = CreationViewController()
                vc.setScrollManager(self?.scrollManager)
                return vc
            }
        ]
        
        pageManager.configure(with: configs)
        
        // 配置菜单
        let menuItems = pageManager.allTitles.map { MenuItem(title: $0) }
        stickyMenuView.configure(with: menuItems)
        
        // 设置页面数量（不立即创建页面）
        pageContainer.setPageCount(pageManager.count)
    }
    
    private func setupGestureExclusion() {
        // 添加 pageContainer 的 collectionView 到排除列表
        mainScrollView.addExcludeSuperView(pageContainer.pageCollectionView)
        
        // 延迟添加已加载页面中的 collectionView
        updateGestureExclusion()
    }
    
    /// 更新手势排除列表（当新页面加载时调用）
    private func updateGestureExclusion() {
        let allCollectionViews = pageContainer.getAllPageCollectionViews()
        for cv in allCollectionViews {
            mainScrollView.addExcludeSuperView(cv)
        }
    }
    
    private func updateContentSize() {
        let contentHeight = view.bounds.height - headerBarHeight - menuHeight
        
        if containerHeightConstraint == nil {
            containerHeightConstraint = pageContainer.view.heightAnchor.constraint(equalToConstant: contentHeight)
            containerHeightConstraint?.isActive = true
        } else {
            containerHeightConstraint?.constant = contentHeight
        }
        
        let totalHeight = headerBarHeight + profileHeaderView.bounds.height + menuHeight + contentHeight
        mainScrollView.contentSize = CGSize(width: view.bounds.width, height: totalHeight)
    }
    
    private func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        let avatarBottomY = profileHeaderView.avatarBottomY + headerBarHeight
        let headerBarProgress = min(1, max(0, offsetY / avatarBottomY))
        headerBar.updateAppearance(progress: headerBarProgress)
        
        scrollManager.handleParentScroll(scrollView)
        
        updateStickyMenuPosition(offsetY: min(offsetY, profileHeaderView.bounds.height))
    }
    
    private func updateStickyMenuPosition(offsetY: CGFloat) {
        let stickyPoint = profileHeaderView.bounds.height
        
        if offsetY >= stickyPoint {
            stickyMenuView.transform = CGAffineTransform(translationX: 0, y: offsetY - stickyPoint)
        } else {
            stickyMenuView.transform = .identity
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

// MARK: - MenuViewDelegate
extension ProfileViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        pageContainer.scrollToPage(at: index, animated: true)
    }
}

// MARK: - PageContainerDelegate
extension ProfileViewController: PageContainerDelegate {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int) {
        stickyMenuView.selectItem(at: index)
        
        // 更新手势排除列表
        updateGestureExclusion()
        
        // 更新 currentChild
        if let page = pageManager.cachedPage(at: index),
           let scrollChild = page.getCurrentScrollChild() {
            scrollManager.currentChild = scrollChild
        }
    }
    
    func pageContainer(_ container: PageContainerViewController, needsPageAt index: Int) -> UIViewController? {
        // 通过 pageManager 懒加载页面
        guard let page = pageManager.page(at: index) else { return nil }
        
        // 更新手势排除列表
        DispatchQueue.main.async {
            self.updateGestureExclusion()
        }
        
        // 如果是当前页面，更新 currentChild
        if index == container.currentIndex,
           let scrollChild = page.getCurrentScrollChild() {
            scrollManager.currentChild = scrollChild
        }
        
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
