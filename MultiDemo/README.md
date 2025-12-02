# MultiDemo - iOS 个人页面组件化框架

## 系统要求

**iOS 13.0+**

---

## 项目架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              App 层                                      │
│                      (AppDelegate, SceneDelegate)                        │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          ▼                       ▼                       ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│    Profile 模块      │ │   AssetFlow 模块     │ │    Common 模块      │
│    (组装层)          │ │   (业务模块)         │ │   (叶子节点)        │
│                     │ │                     │ │                     │
│ ProfileViewController│ │ AppearanceVC        │ │ WorksFlowVC         │
│ ProfileHeaderView   │ │ CreationVC          │ │                     │
│                     │ │ InteractionVC       │ │                     │
└─────────┬───────────┘ └─────────┬───────────┘ └─────────┬───────────┘
          │                       │                       │
          │      import StickyScrollKit                   │
          └───────────────────────┴───────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        StickyScrollKit (SPM 包)                          │
│                                                                         │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │                      Components 层                             │    │
│   │   • StickyHeaderContainerView    通用吸顶容器                  │    │
│   │   • StickyPageProtocol           页面协议                      │    │
│   │   • MenuView                     通用菜单                      │    │
│   └───────────────────────────────────────────────────────────────┘    │
│                                  │                                      │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │                        Core 层                                 │    │
│   │   • NestedScrollChildProtocol    子视图协议                    │    │
│   │   • NestedScrollContainerProtocol 容器协议（约定大于配置）      │    │
│   │   • NestedScrollManager          滚动状态管理器                │    │
│   └───────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 目录结构

```
MultiDemo/
│
├── Packages/                               # 本地 SPM 包
│   └── StickyScrollKit/                    # 通用吸顶滚动组件库
│       ├── Package.swift
│       ├── README.md                       # 组件库文档
│       └── Sources/StickyScrollKit/
│           ├── Core/                       # 嵌套滚动核心
│           │   └── NestedScrollProtocol.swift
│           └── Components/                 # 通用组件
│               ├── Menu/
│               │   └── MenuView.swift
│               └── StickyContainer/
│                   ├── StickyHeaderProtocol.swift
│                   └── StickyHeaderContainerView.swift
│
├── MultiDemo/                              # 主应用
│   ├── App/                                # 应用层
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   │
│   ├── Profile/                            # 个人页面模块
│   │   ├── Container/
│   │   │   └── ProfileViewController.swift # 使用 StickyHeaderContainerView
│   │   └── Header/
│   │       └── ProfileHeaderView.swift
│   │
│   ├── AssetFlow/                          # 资产流模块
│   │   ├── Protocol/
│   │   │   └── AssetFlowProtocol.swift     # 继承 StickyPageProtocol
│   │   ├── Container/
│   │   │   └── AssetFlowContainerView.swift
│   │   └── Modules/                        # 业务子模块
│   │       ├── Appearance/                 # 出境模块
│   │       ├── Creation/                   # 创作模块
│   │       └── Interaction/                # 互动模块
│   │
│   └── Common/                             # 公共业务组件
│       └── WorksFlowViewController.swift   # 实现 NestedScrollChildProtocol
│
└── MultiDemo.xcodeproj/
```

---

## SPM 包集成

通用组件已封装为独立的 Swift Package：**StickyScrollKit**

### 安装方式

1. 打开 Xcode 项目
2. 选择 **File** → **Add Package Dependencies...**
3. 点击 **Add Local...**
4. 选择 `Packages/StickyScrollKit` 目录
5. 在 Target 中勾选 **StickyScrollKit**

### 使用方式

```swift
import StickyScrollKit

// 使用嵌套滚动协议
class MyVC: UIViewController, NestedScrollChildProtocol { ... }

// 使用吸顶容器
let container = StickyHeaderContainerView()

// 使用响应链自动发现容器
if let container = view.findNestedScrollContainer() {
    container.registerScrollableChild(self)
}
```

---

## 快速接入指南

### 方式一：直接使用 StickyHeaderContainerView

```swift
import StickyScrollKit

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
        stickyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let config = StickyContainerConfig(
            menuHeight: 48,
            stickyOffset: view.safeAreaInsets.top + 44,
            initialPageIndex: 0,
            bounces: true
        )
        
        stickyContainer.configure(
            with: config,
            headerView: myHeaderView,
            menuView: nil
        )
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        stickyContainer.updateStickyOffset(view.safeAreaInsets.top + 44)
    }
}

extension MyViewController: StickyContainerDataSource {
    func numberOfPages(in container: StickyHeaderContainerView) -> Int { 3 }
    
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         titleForPageAt index: Int) -> String {
        ["Tab1", "Tab2", "Tab3"][index]
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

### 方式二：使用 ProfileViewController

```swift
let profileVC = ProfileViewController()
profileVC.assetFlowDataSource = MyAssetFlowDataSource()
profileVC.defaultAssetFlowIndex = 1
```

---

## 约定大于配置

叶子节点通过响应链自动发现容器，**无需层层传递闭包**：

```swift
class WorksFlowViewController: UIViewController, NestedScrollChildProtocol {
    
    var childScrollView: UIScrollView { collectionView }
    var canChildScroll: Bool = false
    
    private weak var nestedContainer: NestedScrollContainerProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // ✅ 自动发现容器并注册
        nestedContainer = view.findNestedScrollContainer()
        nestedContainer?.registerScrollableChild(self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // ✅ 自动调用容器处理滚动
        nestedContainer?.handleChildScroll(scrollView)
    }
}
```

### 优势对比

| 方面 | 改造前 | 闭包方式 | 响应链方式 |
|-----|-------|---------|-----------|
| 业务模块依赖 | ❌ 直接依赖 Manager | ✅ 仅依赖闭包 | ✅✅ 仅依赖协议 |
| 代码复杂度 | ❌ 高 | ⚠️ 需层层传递 | ✅ 自动发现 |
| 新增模块 | ❌ 需修改多处 | ⚠️ 需绑定闭包 | ✅ 自动注册 |
| 多团队协作 | ❌ 需理解滚动管理 | ✅ 只需实现协议 | ✅✅ 遵循约定即可 |

---

## 协议规范

### StickyPageProtocol

每个分页内容需要实现此协议：

```swift
public protocol StickyPageProtocol: UIViewController {
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    func setScrollCallbacks(
        onScroll: @escaping (UIScrollView) -> Void,
        onChildChanged: @escaping (NestedScrollChildProtocol) -> Void
    )
    func getAllHorizontalScrollViews() -> [UIScrollView]
    
    // 页面生命周期（有默认空实现）
    func pageWillAppear()
    func pageDidAppear()
    func pageWillDisappear()
    func pageDidDisappear()
}
```

### NestedScrollChildProtocol

叶子节点需要实现此协议：

```swift
public protocol NestedScrollChildProtocol: AnyObject {
    var childScrollView: UIScrollView { get }
    var canChildScroll: Bool { get set }
}
```

### NestedScrollContainerProtocol

容器协议（StickyHeaderContainerView 已实现）：

```swift
public protocol NestedScrollContainerProtocol: AnyObject {
    func registerScrollableChild(_ child: NestedScrollChildProtocol)
    func handleChildScroll(_ scrollView: UIScrollView)
}
```

---

## 多团队协作

| 目录/模块 | 负责团队 | 依赖 |
|---------|---------|-----|
| `Packages/StickyScrollKit/` | 基础架构组 | SnapKit |
| `Profile/` | 个人页面组 | StickyScrollKit |
| `AssetFlow/Protocol/` | 个人页面组 | StickyScrollKit |
| `AssetFlow/Modules/Appearance/` | 出境业务组 | AssetFlowProtocol |
| `AssetFlow/Modules/Creation/` | 创作业务组 | AssetFlowProtocol |
| `AssetFlow/Modules/Interaction/` | 互动业务组 | AssetFlowProtocol |
| `Common/` | 公共组件组 | StickyScrollKit |

---

## 组件化拆分建议

| 组件 | SPM 包名 | 说明 | 依赖 |
|-----|---------|------|-----|
| 核心 + 通用组件 | `StickyScrollKit` | 嵌套滚动核心 + 吸顶容器 + 菜单 | SnapKit |
| 个人页面框架 | `ProfileKit` | ProfileViewController + Header | StickyScrollKit |
| 资产流协议 | `AssetFlowProtocol` | 资产流协议定义 | StickyScrollKit |
| 各业务模块 | 独立 Pod/SPM | 各团队独立维护 | AssetFlowProtocol |

---

## 注意事项

### 1. 安全区域处理

```swift
override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    stickyContainer.updateStickyOffset(view.safeAreaInsets.top + 44)
}
```

### 2. 子页面懒加载

```swift
func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
    if worksVC == nil {
        worksVC = loadWorksVC()
    }
    return worksVC
}
```

### 3. 闭包与响应链优先级

如果设置了 `onScrollEvent` 闭包，会优先使用闭包方式，不会走响应链：

```swift
// 优先使用闭包（向后兼容）
if let handler = onScrollEvent {
    handler(scrollView)
} else {
    // 使用响应链
    nestedContainer?.handleChildScroll(scrollView)
}
```
