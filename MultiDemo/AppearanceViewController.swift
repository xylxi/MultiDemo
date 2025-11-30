import UIKit

// MARK: - 出境模块 ViewController
// 负责人：开发者 A
// 功能：展示用户出境相关的内容（作品、喜欢、点赞）

class AppearanceViewController: UIViewController, CategoryPageProtocol {
    
    // MARK: - CategoryPageProtocol
    static var categoryTitle: String { "出境" }
    
    func getCurrentScrollChild() -> NestedScrollChildProtocol? {
        return currentWorksFlowVC
    }
    
    // MARK: - Properties
    weak var scrollManager: NestedScrollManager?
    private var pageManager = CategoryPageManager()
    private var currentWorksFlowVC: WorksFlowViewController?
    
    // MARK: - 子分类配置
    private let subCategories: [(title: String, color: UIColor)] = [
        ("作品", .systemBlue),
        ("喜欢", UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1)), // iOS 13 兼容色
        ("点赞", .systemTeal)
    ]
    
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
        
        print("[AppearanceViewController] viewDidLoad - 出境模块已加载")
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
        let menuItems = subCategories.map { MenuItem(title: $0.title) }
        menuView.configure(with: menuItems)
        
        // 设置页面数量（不立即创建）
        pageContainer.setPageCount(subCategories.count)
    }
    
    /// 设置 scrollManager（由父容器调用）
    func setScrollManager(_ manager: NestedScrollManager?) {
        self.scrollManager = manager
        pageContainer.scrollManager = manager
    }
}

// MARK: - MenuViewDelegate
extension AppearanceViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        pageContainer.scrollToPage(at: index, animated: true)
    }
}

// MARK: - PageContainerDelegate
extension AppearanceViewController: PageContainerDelegate {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int) {
        menuView.selectItem(at: index)
        
        // 更新当前作品流
        if let worksVC = container.getAllPageCollectionViews().first?.delegate as? WorksFlowViewController {
            currentWorksFlowVC = worksVC
        }
        
        // 通知父容器更新 currentChild
        if let worksVC = currentWorksFlowVC {
            scrollManager?.currentChild = worksVC
        }
    }
    
    func pageContainer(_ container: PageContainerViewController, needsPageAt index: Int) -> UIViewController? {
        guard index >= 0 && index < subCategories.count else { return nil }
        
        let category = subCategories[index]
        let path = "出境 > \(category.title)"
        
        let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
        worksVC.scrollManager = scrollManager
        
        // 如果是第一个页面，设置为当前
        if index == container.currentIndex {
            currentWorksFlowVC = worksVC
            scrollManager?.currentChild = worksVC
        }
        
        print("[AppearanceViewController] 懒加载页面: \(path)")
        
        return worksVC
    }
}
