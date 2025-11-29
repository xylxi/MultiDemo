import UIKit

// MARK: - 支持同时识别手势的 ScrollView
class NestedParentScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    /// 允许同时识别多个手势
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                          shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - ProfileViewController
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
    private var containerHeightConstraint: NSLayoutConstraint?
    private var isFirstLayout = true
    
    // MARK: - 分类配置
    private lazy var categories: [CategoryItem] = {
        return [
            CategoryItem(
                title: "出境",
                color: .systemBlue,
                subCategories: [
                    CategoryItem(title: "作品", color: .systemBlue),
                    CategoryItem(title: "喜欢", color: .systemCyan),
                    CategoryItem(title: "点赞", color: .systemTeal)
                ]
            ),
            CategoryItem(
                title: "创作",
                color: .systemPink,
                subCategories: [
                    CategoryItem(title: "发布", color: .systemPink),
                    CategoryItem(
                        title: "资产",
                        color: .systemOrange,
                        subCategories: [
                            CategoryItem(title: "全部", color: .systemOrange),
                            CategoryItem(title: "图片", color: .systemYellow),
                            CategoryItem(title: "视频", color: .systemGreen),
                            CategoryItem(title: "收藏", color: .systemMint)
                        ]
                    ),
                    CategoryItem(title: "喜欢", color: .systemIndigo)
                ]
            )
        ]
    }()
    
    // MARK: - UI Components
    private lazy var headerBar: ProfileHeaderBar = {
        let bar = ProfileHeaderBar()
        bar.configure(title: mockProfile.name)
        return bar
    }()
    
    // 使用自定义的支持同时识别手势的 ScrollView
    private lazy var mainScrollView: NestedParentScrollView = {
        let sv = NestedParentScrollView()
        sv.delegate = self
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.bounces = true
        sv.alwaysBounceVertical = true
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
    
    private lazy var categoryContainer: CategoryContainerViewController = {
        let container = CategoryContainerViewController(
            categories: categories,
            categoryPath: "",
            showMenu: false // 一级菜单由 stickyMenuView 负责
        )
        container.scrollManager = scrollManager
        container.containerDelegate = self
        return container
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
        setupCategories()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
        
        // 首次布局完成后，初始化当前子视图
        if isFirstLayout && profileHeaderView.bounds.height > 0 {
            isFirstLayout = false
            DispatchQueue.main.async {
                self.categoryContainer.updateCurrentChild()
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Main ScrollView
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
        
        // Profile Header
        contentView.addSubview(profileHeaderView)
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: headerBarHeight),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Sticky Menu
        contentView.addSubview(stickyMenuView)
        stickyMenuView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickyMenuView.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor),
            stickyMenuView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stickyMenuView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stickyMenuView.heightAnchor.constraint(equalToConstant: menuHeight)
        ])
        
        // Category Container
        addChild(categoryContainer)
        contentView.addSubview(categoryContainer.view)
        categoryContainer.didMove(toParent: self)
        
        categoryContainer.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryContainer.view.topAnchor.constraint(equalTo: stickyMenuView.bottomAnchor),
            categoryContainer.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryContainer.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryContainer.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Header Bar (最上层)
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
    
    private func setupCategories() {
        let menuItems = categories.map { MenuItem(title: $0.title) }
        stickyMenuView.configure(with: menuItems)
    }
    
    private func updateContentSize() {
        let contentHeight = view.bounds.height - headerBarHeight - menuHeight
        
        if containerHeightConstraint == nil {
            containerHeightConstraint = categoryContainer.view.heightAnchor.constraint(equalToConstant: contentHeight)
            containerHeightConstraint?.isActive = true
        } else {
            containerHeightConstraint?.constant = contentHeight
        }
        
        let totalHeight = headerBarHeight + profileHeaderView.bounds.height + menuHeight + contentHeight
        mainScrollView.contentSize = CGSize(width: view.bounds.width, height: totalHeight)
    }
    
    // MARK: - Scroll Handling
    private func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        // 计算 HeaderBar 背景透明度
        let avatarBottomY = profileHeaderView.avatarBottomY + headerBarHeight
        let headerBarProgress = min(1, max(0, offsetY / avatarBottomY))
        headerBar.updateAppearance(progress: headerBarProgress)
        
        // 使用 scrollManager 处理嵌套滚动
        scrollManager.handleParentScroll(scrollView)
        
        // 更新吸顶菜单位置
        updateStickyMenuPosition(offsetY: min(offsetY, profileHeaderView.bounds.height))
    }
    
    private func updateStickyMenuPosition(offsetY: CGFloat) {
        let stickyPoint = profileHeaderView.bounds.height
        
        if offsetY >= stickyPoint {
            // 菜单吸顶
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
        categoryContainer.scrollToPage(at: index, animated: true)
    }
}

// MARK: - CategoryContainerDelegate
extension ProfileViewController: CategoryContainerDelegate {
    func categoryContainerDidChangeSelection(_ container: CategoryContainerViewController) {
        // 更新当前滚动子视图
        categoryContainer.updateCurrentChild()
    }
}

// MARK: - Preview
#if DEBUG
import SwiftUI

struct ProfileViewController_Preview: PreviewProvider {
    static var previews: some View {
        ProfileViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct ProfileViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ProfileViewController {
        return ProfileViewController()
    }
    
    func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {}
}
#endif
