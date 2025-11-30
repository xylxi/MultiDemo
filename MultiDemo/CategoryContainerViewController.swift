import UIKit

// MARK: - 分类项配置
struct CategoryItem {
    let title: String
    let color: UIColor
    var subCategories: [CategoryItem]?
    
    init(title: String, color: UIColor, subCategories: [CategoryItem]? = nil) {
        self.title = title
        self.color = color
        self.subCategories = subCategories
    }
}

// MARK: - 分类容器代理
protocol CategoryContainerDelegate: AnyObject {
    func categoryContainerDidChangeSelection(_ container: CategoryContainerViewController)
}

// MARK: - 分类容器 ViewController
class CategoryContainerViewController: UIViewController {
    
    weak var scrollManager: NestedScrollManager?
    weak var containerDelegate: CategoryContainerDelegate?
    
    private let categories: [CategoryItem]
    private let categoryPath: String
    private let showMenu: Bool
    
    private(set) var pageContainer: PageContainerViewController?
    private var childControllers: [UIViewController] = []
    
    var currentIndex: Int {
        return pageContainer?.currentIndex ?? 0
    }
    
    private lazy var menuView: MenuView = {
        let menu = MenuView()
        menu.delegate = self
        return menu
    }()
    
    // MARK: - Init
    init(categories: [CategoryItem], categoryPath: String = "", showMenu: Bool = true) {
        self.categories = categories
        self.categoryPath = categoryPath
        self.showMenu = showMenu
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupChildControllers()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        if showMenu {
            view.addSubview(menuView)
            menuView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                menuView.topAnchor.constraint(equalTo: view.topAnchor),
                menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                menuView.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        let pc = PageContainerViewController()
        pc.delegate = self
        pc.scrollManager = scrollManager
        pageContainer = pc
        addChild(pc)
        view.addSubview(pc.view)
        pc.didMove(toParent: self)
        
        pc.view.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = showMenu 
            ? pc.view.topAnchor.constraint(equalTo: menuView.bottomAnchor)
            : pc.view.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            topConstraint,
            pc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupChildControllers() {
        let menuItems = categories.map { MenuItem(title: $0.title, hasChildren: $0.subCategories != nil) }
        menuView.configure(with: menuItems)
        
        childControllers = categories.enumerated().map { index, category in
            let path = categoryPath.isEmpty ? category.title : "\(categoryPath) > \(category.title)"
            
            if let subCategories = category.subCategories {
                let container = CategoryContainerViewController(
                    categories: subCategories,
                    categoryPath: path,
                    showMenu: true
                )
                container.scrollManager = scrollManager
                container.containerDelegate = self
                return container
            } else {
                let worksVC = WorksFlowViewController(categoryPath: path, color: category.color)
                worksVC.scrollManager = scrollManager
                return worksVC
            }
        }
        
        pageContainer?.configure(with: childControllers)
    }
    
    func updateCurrentChild() {
        guard let pageContainer = pageContainer else { return }
        
        let index = pageContainer.currentIndex
        guard index < childControllers.count else { return }
        
        let currentVC = childControllers[index]
        
        if let child = currentVC as? NestedScrollChildProtocol {
            scrollManager?.currentChild = child
        } else if let container = currentVC as? CategoryContainerViewController {
            if container.isViewLoaded {
                container.updateCurrentChild()
            } else {
                _ = container.view
                DispatchQueue.main.async {
                    container.updateCurrentChild()
                }
            }
        }
    }
    
    func scrollToPage(at index: Int, animated: Bool = true) {
        pageContainer?.scrollToPage(at: index, animated: animated)
        menuView.selectItem(at: index, animated: animated)
    }
    
    /// 获取所有嵌套的 PageCollectionView
    func getAllPageCollectionViews() -> [UICollectionView]? {
        guard let pageContainer = pageContainer else { return nil }
        return pageContainer.getAllPageCollectionViews()
    }
    
    func getCurrentWorksFlowVC() -> WorksFlowViewController? {
        guard let pageContainer = pageContainer else { return nil }
        
        let index = pageContainer.currentIndex
        guard index < childControllers.count else { return nil }
        
        if let worksVC = childControllers[index] as? WorksFlowViewController {
            return worksVC
        } else if let container = childControllers[index] as? CategoryContainerViewController {
            return container.getCurrentWorksFlowVC()
        }
        return nil
    }
}

// MARK: - MenuViewDelegate
extension CategoryContainerViewController: MenuViewDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int) {
        pageContainer?.scrollToPage(at: index, animated: true)
    }
}

// MARK: - PageContainerDelegate
extension CategoryContainerViewController: PageContainerDelegate {
    func pageContainer(_ container: PageContainerViewController, didScrollToIndex index: Int) {
        menuView.selectItem(at: index)
        updateCurrentChild()
        containerDelegate?.categoryContainerDidChangeSelection(self)
    }
}

// MARK: - CategoryContainerDelegate
extension CategoryContainerViewController: CategoryContainerDelegate {
    func categoryContainerDidChangeSelection(_ container: CategoryContainerViewController) {
        containerDelegate?.categoryContainerDidChangeSelection(self)
    }
}
