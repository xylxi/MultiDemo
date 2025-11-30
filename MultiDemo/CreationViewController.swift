import UIKit

// MARK: - 创作模块 ViewController
// 负责人：开发者 B
// 功能：展示用户创作相关的内容（发布、资产、喜欢）

class CreationViewController: UIViewController, CategoryPageProtocol {
    
    // MARK: - CategoryPageProtocol
    static var categoryTitle: String { "创作" }
    
    func getCurrentScrollChild() -> NestedScrollChildProtocol? {
        return currentScrollChild
    }
    
    // MARK: - Properties
    weak var scrollManager: NestedScrollManager?
    private weak var currentScrollChild: NestedScrollChildProtocol?
    
    // MARK: - 子分类配置
    private enum SubCategory: Int, CaseIterable {
        case publish = 0
        case assets
        case like
        
        var title: String {
            switch self {
            case .publish: return "发布"
            case .assets: return "资产"
            case .like: return "喜欢"
            }
        }
        
        var color: UIColor {
            switch self {
            case .publish: return .systemPink
            case .assets: return .systemOrange
            case .like: return .systemIndigo
            }
        }
        
        var hasSubCategories: Bool {
            return self == .assets
        }
    }
    
    // MARK: - UI
    private lazy var menuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        return menu
    }()
    
    private lazy var pageContainer: PageContainerViewController = {
        let pc = PageContainerViewController()
        pc.delegate = self
        pc.scrollManager = scrollManager
        return pc
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
        
        print("[CreationViewController] viewDidLoad - 创作模块已加载")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Menu
        view.addSubview(menuView)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: view.topAnchor),
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Page Container
        addChild(pageContainer)
        view.addSubview(pageContainer.view)
        pageContainer.didMove(toParent: self)
        
        pageContainer.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageContainer.view.topAnchor.constraint(equalTo: menuView.bottomAnchor),
            pageContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupPages() {
        // 配置菜单
        let menuItems = SubCategory.allCases.map { MenuItem(title: $0.title, hasChildren: $0.hasSubCategories) }
        menuView.configure(with: menuItems)
        
        // 设置页面数量（不立即创建）
        pageContainer.setPageCount(SubCategory.allCases.count)
    }
    
    /// 设置 scrollManager（由父容器调用）
    func setScrollManager(_ manager: NestedScrollManager?) {
        self.scrollManager = manager
        pageContainer.scrollManager = manager
    }
}

// MARK: - MenuViewDelegate
extension CreationViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        pageContainer.scrollToPage(at: index, animated: true)
    }
}

// MARK: - PageContainerDelegate
extension CreationViewController: PageContainerDelegate {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int) {
        menuView.selectItem(at: index)
        updateCurrentScrollChild()
    }
    
    func pageContainer(_ container: PageContainerViewController, needsPageAt index: Int) -> UIViewController? {
        guard let category = SubCategory(rawValue: index) else { return nil }
        
        if category == .assets {
            // 资产页面有三级分类，创建 AssetsViewController
            let assetsVC = AssetsViewController()
            assetsVC.setScrollManager(scrollManager)
            
            print("[CreationViewController] 懒加载页面: 创作 > 资产 (有子分类)")
            
            return assetsVC
        } else {
            // 其他页面直接是作品流
            let path = "创作 > \(category.title)"
            let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
            worksVC.scrollManager = scrollManager
            
            if index == container.currentIndex {
                currentScrollChild = worksVC
                scrollManager?.currentChild = worksVC
            }
            
            print("[CreationViewController] 懒加载页面: \(path)")
            
            return worksVC
        }
    }
    
    private func updateCurrentScrollChild() {
        // 这里需要根据当前页面类型更新 currentScrollChild
        // 实际实现中可以通过遍历已加载的页面来获取
    }
}

// MARK: - 资产 ViewController（三级分类）
// 属于创作模块的子模块
class AssetsViewController: UIViewController, CategoryPageProtocol {
    
    static var categoryTitle: String { "资产" }
    
    func getCurrentScrollChild() -> NestedScrollChildProtocol? {
        return currentWorksFlowVC
    }
    
    weak var scrollManager: NestedScrollManager?
    private var currentWorksFlowVC: WorksFlowViewController?
    
    // 资产的子分类
    private let subCategories: [(title: String, color: UIColor)] = [
        ("全部", .systemOrange),
        ("图片", .systemYellow),
        ("视频", .systemGreen),
        ("收藏", UIColor(red: 0.0, green: 0.78, blue: 0.74, alpha: 1)) // iOS 13 兼容色（替代 systemMint）
    ]
    
    private lazy var menuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        return menu
    }()
    
    private lazy var pageContainer: PageContainerViewController = {
        let pc = PageContainerViewController()
        pc.delegate = self
        pc.scrollManager = scrollManager
        return pc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
        
        print("[AssetsViewController] viewDidLoad - 资产模块已加载")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(menuView)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: view.topAnchor),
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        addChild(pageContainer)
        view.addSubview(pageContainer.view)
        pageContainer.didMove(toParent: self)
        
        pageContainer.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageContainer.view.topAnchor.constraint(equalTo: menuView.bottomAnchor),
            pageContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupPages() {
        let menuItems = subCategories.map { MenuItem(title: $0.title) }
        menuView.configure(with: menuItems)
        pageContainer.setPageCount(subCategories.count)
    }
    
    func setScrollManager(_ manager: NestedScrollManager?) {
        self.scrollManager = manager
        pageContainer.scrollManager = manager
    }
}

// MARK: - AssetsViewController + MenuViewDelegate
extension AssetsViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        pageContainer.scrollToPage(at: index, animated: true)
    }
}

// MARK: - AssetsViewController + PageContainerDelegate
extension AssetsViewController: PageContainerDelegate {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int) {
        menuView.selectItem(at: index)
        
        if let worksVC = currentWorksFlowVC {
            scrollManager?.currentChild = worksVC
        }
    }
    
    func pageContainer(_ container: PageContainerViewController, needsPageAt index: Int) -> UIViewController? {
        guard index >= 0 && index < subCategories.count else { return nil }
        
        let category = subCategories[index]
        let path = "创作 > 资产 > \(category.title)"
        
        let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
        worksVC.scrollManager = scrollManager
        
        if index == container.currentIndex {
            currentWorksFlowVC = worksVC
            scrollManager?.currentChild = worksVC
        }
        
        print("[AssetsViewController] 懒加载页面: \(path)")
        
        return worksVC
    }
}
