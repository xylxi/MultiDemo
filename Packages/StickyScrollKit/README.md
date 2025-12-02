# StickyScrollKit

一个通用的 iOS 吸顶滚动组件库，支持嵌套滚动、吸顶效果和分页内容。

## 系统要求

- iOS 13.0+
- Swift 5.9+

## 安装

### Swift Package Manager

#### 本地包（开发阶段）

```swift
dependencies: [
    .package(path: "../Packages/StickyScrollKit")
]
```

#### 远程仓库（发布后）

```swift
dependencies: [
    .package(url: "https://github.com/your-org/StickyScrollKit.git", from: "1.0.0")
]
```

#### Xcode 添加

1. **File** → **Add Package Dependencies...**
2. 输入仓库 URL 或点击 **Add Local...** 选择本地目录
3. 在 Target 中勾选 **StickyScrollKit**

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                      StickyScrollKit                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Components 层                          │   │
│  │                                                         │   │
│  │   ┌─────────────────────┐  ┌─────────────────────────┐  │   │
│  │   │   StickyContainer   │  │       Menu              │  │   │
│  │   │                     │  │                         │  │   │
│  │   │ • StickyHeader-     │  │ • MenuItem              │  │   │
│  │   │   ContainerView     │  │ • MenuView              │  │   │
│  │   │ • StickyPageProtocol│  │ • MenuViewDelegate      │  │   │
│  │   │ • StickyContainer-  │  │                         │  │   │
│  │   │   DataSource        │  │                         │  │   │
│  │   │ • StickyContainer-  │  │                         │  │   │
│  │   │   Delegate          │  │                         │  │   │
│  │   │ • DefaultStickyMenu │  │                         │  │   │
│  │   └─────────────────────┘  └─────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ▲                                  │
│                              │ 依赖                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Core 层                             │   │
│  │                                                         │   │
│  │   • NestedScrollChildProtocol     子视图协议            │   │
│  │   • NestedScrollParentProtocol    父视图协议            │   │
│  │   • NestedScrollContainerProtocol 容器协议（约定大于配置）│   │
│  │   • NestedScrollManager           滚动状态管理器        │   │
│  │   • NestedParentScrollView        手势排除 ScrollView   │   │
│  │   • UIResponder.findNestedScrollContainer() 响应链扩展  │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## API 概览

### Core 层

| 组件 | 说明 |
|-----|------|
| `NestedScrollChildProtocol` | 子视图协议，提供 `childScrollView` 和 `canChildScroll` |
| `NestedScrollParentProtocol` | 父视图协议，提供 `parentScrollView` 和 `headerHeight` |
| `NestedScrollContainerProtocol` | 容器协议，支持响应链自动发现 |
| `NestedScrollManager` | 管理父子视图滚动状态切换 |
| `NestedParentScrollView` | 支持手势排除的 UIScrollView 子类 |

### Components 层

| 组件 | 说明 |
|-----|------|
| `StickyHeaderContainerView` | 通用吸顶容器视图（核心组件） |
| `StickyContainerConfig` | 容器配置（menuHeight、stickyOffset 等） |
| `StickyContainerDataSource` | 数据源协议（页面数量、标题、实例） |
| `StickyContainerDelegate` | 代理协议（页面切换、滚动进度） |
| `StickyPageProtocol` | 页面协议（获取滚动子视图、生命周期） |
| `StickyMenuViewProtocol` | 菜单协议（可自定义菜单） |
| `DefaultStickyMenuView` | 默认菜单实现 |
| `MenuItem` | 菜单项模型 |
| `MenuView` | 通用菜单视图 |

---

## 快速开始

### 1. 导入模块

```swift
import StickyScrollKit
```

### 2. 创建容器

```swift
class MyViewController: UIViewController {
    
    private lazy var stickyContainer: StickyHeaderContainerView = {
        let container = StickyHeaderContainerView()
        container.dataSource = self
        container.delegate = self
        return container
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(stickyContainer)
        stickyContainer.frame = view.bounds
        
        let config = StickyContainerConfig(
            menuHeight: 48,
            stickyOffset: view.safeAreaInsets.top + 44,
            initialPageIndex: 0,
            bounces: true
        )
        
        stickyContainer.configure(
            with: config,
            headerView: myHeaderView,
            menuView: nil  // 使用默认菜单
        )
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // ⚠️ 安全区域变化后更新 stickyOffset
        stickyContainer.updateStickyOffset(view.safeAreaInsets.top + 44)
    }
}
```

### 3. 实现数据源

```swift
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
```

### 4. 实现页面协议

```swift
class MyPageViewController: UIViewController, StickyPageProtocol {
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        return contentViewController  // 返回包含 ScrollView 的子控制器
    }
    
    func setScrollCallbacks(
        onScroll: @escaping (UIScrollView) -> Void,
        onChildChanged: @escaping (NestedScrollChildProtocol) -> Void
    ) {
        // 使用响应链方式时可留空
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [pageCollectionView]  // 返回内部水平滚动视图
    }
}
```

---

## 约定大于配置

叶子节点通过响应链自动发现容器，**无需层层传递闭包**：

```swift
class ContentViewController: UIViewController, NestedScrollChildProtocol {
    
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

### 优势对比

| 方面 | 闭包传递方式 | 响应链方式 |
|-----|------------|----------|
| 代码量 | 每层需传递闭包 | 叶子节点一次查找 |
| 耦合度 | 层层依赖 | 仅依赖协议 |
| 新增模块 | 需手动绑定 | 自动注册 |
| 维护成本 | 高 | 低 |

---

## 目录结构

```
StickyScrollKit/
├── Package.swift
├── README.md
└── Sources/StickyScrollKit/
    ├── StickyScrollKit.swift           # 模块入口
    ├── Core/
    │   └── NestedScrollProtocol.swift  # 嵌套滚动核心协议与管理器
    └── Components/
        ├── Menu/
        │   └── MenuView.swift          # 通用菜单组件
        └── StickyContainer/
            ├── StickyHeaderProtocol.swift      # 吸顶容器协议
            └── StickyHeaderContainerView.swift # 吸顶容器视图
```

---

## License

MIT
