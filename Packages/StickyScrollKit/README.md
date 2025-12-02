# StickyScrollKit

一个通用的 iOS 吸顶滚动组件库，支持嵌套滚动、吸顶效果和分页内容。

## 系统要求

- iOS 13.0+
- Swift 5.9+

## 安装

### Swift Package Manager

#### 方式一：Xcode 添加本地包（推荐）

1. 打开 Xcode 项目
2. 选择 **File** → **Add Package Dependencies...**
3. 点击 **Add Local...**
4. 选择 `Packages/StickyScrollKit` 目录
5. 点击 **Add Package**
6. 在 **Add to Target** 中勾选你的主 Target

#### 方式二：Package.swift 依赖（远程仓库）

```swift
dependencies: [
    .package(url: "https://github.com/your-org/StickyScrollKit.git", from: "1.0.0")
]
```

## 主要组件

### Core - 嵌套滚动核心

| 组件 | 说明 |
|-----|------|
| `NestedScrollChildProtocol` | 子视图协议 |
| `NestedScrollParentProtocol` | 父视图协议 |
| `NestedScrollContainerProtocol` | 容器协议（约定大于配置） |
| `NestedScrollManager` | 嵌套滚动管理器 |
| `NestedParentScrollView` | 支持手势排除的 ScrollView |

### Components/Menu - 菜单组件

| 组件 | 说明 |
|-----|------|
| `MenuItem` | 菜单项模型 |
| `MenuView` | 通用菜单视图 |
| `MenuViewDelegate` | 菜单代理 |

### Components/StickyContainer - 吸顶容器

| 组件 | 说明 |
|-----|------|
| `StickyHeaderContainerView` | 通用吸顶容器视图 |
| `StickyContainerConfig` | 容器配置 |
| `StickyContainerDataSource` | 数据源协议 |
| `StickyContainerDelegate` | 代理协议 |
| `StickyPageProtocol` | 页面协议 |
| `StickyMenuViewProtocol` | 菜单协议 |
| `DefaultStickyMenuView` | 默认菜单实现 |

## 快速开始

```swift
import StickyScrollKit

class MyViewController: UIViewController {
    
    private lazy var stickyContainer: StickyHeaderContainerView = {
        let container = StickyHeaderContainerView()
        container.dataSource = self
        container.delegate = self
        return container
    }()
    
    private lazy var headerView: UIView = {
        // 自定义头部视图
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContainer()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // ⚠️ 安全区域变化后更新 stickyOffset
        let headerBarHeight = view.safeAreaInsets.top + 44
        stickyContainer.updateStickyOffset(headerBarHeight)
    }
    
    private func setupUI() {
        view.addSubview(stickyContainer)
        stickyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configureContainer() {
        let config = StickyContainerConfig(
            menuHeight: 48,
            stickyOffset: 44, // 导航栏高度
            initialPageIndex: 0,
            bounces: true
        )
        
        stickyContainer.configure(
            with: config,
            headerView: headerView,
            menuView: nil // 使用默认菜单
        )
    }
}

// MARK: - StickyContainerDataSource
extension MyViewController: StickyContainerDataSource {
    
    func numberOfPages(in container: StickyHeaderContainerView) -> Int {
        return 3
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         titleForPageAt index: Int) -> String {
        return ["Tab1", "Tab2", "Tab3"][index]
    }
    
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         pageAt index: Int) -> StickyPageProtocol {
        let page = MyPageViewController(index: index)
        addChild(page)
        page.didMove(toParent: self)
        return page
    }
}

// MARK: - StickyContainerDelegate
extension MyViewController: StickyContainerDelegate {
    
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         didSwitchToPageAt index: Int) {
        print("切换到页面 \(index)")
    }
}
```

## 约定大于配置

叶子节点（如 `WorksFlowViewController`）可以通过响应链自动发现容器：

```swift
class MyContentViewController: UIViewController, NestedScrollChildProtocol {
    
    var childScrollView: UIScrollView { collectionView }
    var canChildScroll: Bool = false
    
    private weak var container: NestedScrollContainerProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // ✅ 自动发现容器并注册
        container = view.findNestedScrollContainer()
        container?.registerScrollableChild(self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // ✅ 自动调用容器处理滚动
        container?.handleChildScroll(scrollView)
    }
}
```

## License

MIT

