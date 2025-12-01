# ProfileDemo - iOS 个人页面组件化框架

## 最低支持版本

**iOS 13.0+**

## 目录结构

```
ProfileDemo/
│
├── App/                                    # 应用层
│   ├── AppDelegate.swift                   # App 生命周期
│   ├── SceneDelegate.swift                 # Scene 生命周期
│   └── Info.plist                          # 应用配置
│
├── Core/                                   # 核心层（可独立成 Pod/SPM）
│   └── ScrollManager/
│       └── NestedScrollProtocol.swift      # 嵌套滚动协议与管理器
│
├── Components/                             # 通用组件层（可独立成 Pod/SPM）
│   ├── Menu/
│   │   └── MenuView.swift                  # 分类菜单组件
│   ├── StickyContainer/                    # 🆕 通用吸顶容器
│   │   ├── StickyHeaderProtocol.swift      # 吸顶容器协议规范
│   │   └── StickyHeaderContainerView.swift # 通用吸顶容器视图
│   └── PageContainer/                      # 预留：分页容器组件
│
├── Profile/                                # 个人页面模块（可独立成 Pod/SPM）
│   ├── Container/
│   │   └── ProfileViewController.swift     # 个人页面容器（组装层）
│   └── Header/
│       └── ProfileHeaderView.swift         # 用户信息头部 + HeaderBar
│
├── AssetFlow/                              # 资产流模块（可独立成 Pod/SPM）
│   ├── Protocol/
│   │   └── AssetFlowProtocol.swift         # 资产流协议规范 + 闭包类型定义
│   ├── Container/
│   │   └── AssetFlowContainerView.swift    # 资产流容器视图（可选使用）
│   └── Modules/                            # 业务子模块（各团队独立开发）
│       ├── Appearance/
│       │   └── AppearanceViewController.swift  # 出境模块
│       └── Creation/
│           └── CreationViewController.swift    # 创作模块
│
└── Common/                                 # 公共业务组件
    └── WorksFlowViewController.swift       # 作品流列表（叶子节点）
```

## 🆕 通用吸顶组件（StickyHeaderContainerView）

### 设计目标

将吸顶功能抽取为独立的、**业务无关**的通用组件，支持：

1. **Header 区域**：可自定义的头部视图（滚动时隐藏）
2. **Menu 区域**：吸顶菜单（滚动到顶部后固定显示）
3. **Page 区域**：分页内容容器（支持嵌套滚动）

### 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        屏幕                                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              导航栏 (stickyOffset 区域)                    │  │
│  │                    始终可见                                │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │   StickyHeaderContainerView                               │  │
│  │   ┌───────────────────────────────────────────────────┐   │  │
│  │   │              headerView (可自定义)                 │   │  │
│  │   │           （用户信息、Banner 等）                  │   │  │
│  │   │              ← 滚动时隐藏                          │   │  │
│  │   └───────────────────────────────────────────────────┘   │  │
│  │   ┌───────────────────────────────────────────────────┐   │  │
│  │   │              menuView (吸顶)                       │   │  │
│  │   │           ← 滚动到顶部后固定在导航栏下方            │   │  │
│  │   └───────────────────────────────────────────────────┘   │  │
│  │   ┌───────────────────────────────────────────────────┐   │  │
│  │   │           pageCollectionView                       │   │  │
│  │   │      ┌─────┐ ┌─────┐ ┌─────┐                      │   │  │
│  │   │      │Page1│ │Page2│ │Page3│ ...                  │   │  │
│  │   │      └─────┘ └─────┘ └─────┘                      │   │  │
│  │   │           ← 支持嵌套滚动                           │   │  │
│  │   └───────────────────────────────────────────────────┘   │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 快速接入指南

### 方式一：直接使用 StickyHeaderContainerView（推荐）

#### 1. 创建容器并配置

```swift
class MyViewController: UIViewController {
    
    private lazy var stickyContainer: StickyHeaderContainerView = {
        let container = StickyHeaderContainerView()
        container.dataSource = self
        container.delegate = self
        return container
    }()
    
    /// 自定义头部视图
    private lazy var myHeaderView: UIView = {
        let view = MyCustomHeaderView()
        // 配置头部视图...
        return view
    }()
    
    /// 导航栏高度（安全区域 + 内容高度）
    private var headerBarHeight: CGFloat {
        return view.safeAreaInsets.top + 44
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContainer()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // ⚠️ 重要：安全区域变化后更新 stickyOffset
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
            menuHeight: 48,                    // 菜单高度
            stickyOffset: headerBarHeight,     // 导航栏高度（吸顶位置）
            initialPageIndex: 0,               // 初始页面索引
            bounces: true                      // 是否启用弹性效果
        )
        
        stickyContainer.configure(
            with: config,
            headerView: myHeaderView,          // 自定义头部
            menuView: nil                      // nil 使用默认菜单
        )
    }
}
```

#### 2. 实现数据源协议

```swift
extension MyViewController: StickyContainerDataSource {
    
    /// 返回页面数量
    func numberOfPages(in container: StickyHeaderContainerView) -> Int {
        return 3
    }
    
    /// 返回每个页面的标题（用于菜单显示）
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         titleForPageAt index: Int) -> String {
        return ["Tab1", "Tab2", "Tab3"][index]
    }
    
    /// 创建页面（懒加载，只在需要时调用）
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         pageAt index: Int) -> StickyPageProtocol {
        let page = MyPageViewController(index: index)
        addChild(page)
        page.didMove(toParent: self)
        return page
    }
}
```

#### 3. 实现代理协议（可选）

```swift
extension MyViewController: StickyContainerDelegate {
    
    /// 页面切换回调
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         didSwitchToPageAt index: Int) {
        print("切换到页面 \(index)")
    }
    
    /// 滚动进度回调（0~1，可用于更新导航栏透明度）
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         scrollProgressDidChange progress: CGFloat) {
        navigationBar.alpha = progress
    }
    
    /// 页面加载完成回调
    func stickyContainer(_ container: StickyHeaderContainerView, 
                         didLoadPageAt index: Int, 
                         page: StickyPageProtocol) {
        print("页面 \(index) 加载完成")
    }
}
```

#### 4. 实现子页面协议

每个分页内容需要实现 `StickyPageProtocol`：

```swift
class MyPageViewController: UIViewController, StickyPageProtocol {
    
    private var onScrollEvent: ((UIScrollView) -> Void)?
    private var onCurrentChildChanged: ((NestedScrollChildProtocol) -> Void)?
    
    private var worksVC: WorksFlowViewController?
    
    // MARK: - StickyPageProtocol
    
    /// 返回当前可滚动的子视图（用于嵌套滚动）
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        // ⚠️ 如果子视图还没加载，先加载它
        if worksVC == nil {
            worksVC = loadWorksVC()
        }
        return worksVC
    }
    
    /// 设置滚动回调（容器会调用此方法绑定回调）
    func setScrollCallbacks(
        onScroll: @escaping (UIScrollView) -> Void,
        onChildChanged: @escaping (NestedScrollChildProtocol) -> Void
    ) {
        self.onScrollEvent = onScroll
        self.onCurrentChildChanged = onChildChanged
    }
    
    /// 返回内部水平滚动视图（用于手势排除）
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [pageCollectionView]  // 如果有水平滚动的 CollectionView
    }
    
    // MARK: - 页面生命周期（可选）
    
    func pageWillAppear() { }
    func pageDidAppear() { }
    func pageWillDisappear() { }
    func pageDidDisappear() { }
    
    // MARK: - Private
    
    private func loadWorksVC() -> WorksFlowViewController {
        let vc = WorksFlowViewController(...)
        // ⚠️ 绑定滚动回调
        vc.onScrollEvent = { [weak self] scrollView in
            self?.onScrollEvent?(scrollView)
        }
        addChild(vc)
        vc.didMove(toParent: self)
        return vc
    }
}
```

---

### 方式二：使用 ProfileViewController（个人页面场景）

如果是个人页面场景，可以直接使用封装好的 `ProfileViewController`：

```swift
// 1. 创建 ProfileViewController
let profileVC = ProfileViewController()

// 2. 设置默认定位的页面索引（可选，默认为 0）
profileVC.defaultAssetFlowIndex = 1  // 定位到创作模块

// 3. 配置用户信息
profileVC.configureProfile(UserProfile(
    avatar: "avatar_url",
    name: "用户名",
    userId: "user_id",
    bio: "个人简介",
    followingCount: 100,
    followersCount: 1000,
    likesCount: 5000
))

// 4. 注入资产流数据源
profileVC.assetFlowDataSource = MyAssetFlowDataSource()

// 5. 设置代理（可选）
profileVC.assetFlowDelegate = self
```

实现数据源：

```swift
class MyAssetFlowDataSource: AssetFlowDataSource {
    func assetFlowConfigs() -> [AssetFlowConfig] {
        return [
            AssetFlowConfig(title: "出境") {
                return AppearanceViewController()
            },
            AssetFlowConfig(title: "创作") {
                return CreationViewController()
            }
        ]
    }
}
```

---

## 协议规范

### StickyPageProtocol

每个分页内容需要实现此协议：

```swift
public protocol StickyPageProtocol: UIViewController {
    
    /// 获取当前可滚动的子视图（用于嵌套滚动联动）
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    
    /// 设置滚动事件回调
    func setScrollCallbacks(
        onScroll: @escaping (UIScrollView) -> Void,
        onChildChanged: @escaping (NestedScrollChildProtocol) -> Void
    )
    
    /// 获取内部所有水平滚动的 ScrollView（用于手势排除）
    func getAllHorizontalScrollViews() -> [UIScrollView]
    
    // MARK: - 页面生命周期（有默认空实现）
    func pageWillAppear()
    func pageDidAppear()
    func pageWillDisappear()
    func pageDidDisappear()
}
```

### NestedScrollChildProtocol

叶子节点（如 WorksFlowViewController）需要实现此协议：

```swift
public protocol NestedScrollChildProtocol: AnyObject {
    /// 子视图的 ScrollView
    var childScrollView: UIScrollView { get }
    
    /// 是否允许子视图滚动（由 NestedScrollManager 控制）
    var canChildScroll: Bool { get set }
}
```

### StickyContainerConfig

容器配置参数：

```swift
public struct StickyContainerConfig {
    /// 菜单高度（默认 48）
    public var menuHeight: CGFloat
    
    /// 吸顶偏移量（顶部始终显示的高度，如导航栏高度）
    public var stickyOffset: CGFloat
    
    /// 初始选中的页面索引（默认 0）
    public var initialPageIndex: Int
    
    /// 是否启用弹性效果（默认 true）
    public var bounces: Bool
}
```

---

## 注意事项

### 1. 安全区域处理

由于 `viewDidLoad` 时 `safeAreaInsets` 可能还未正确设置，需要在 `viewSafeAreaInsetsDidChange` 中更新 `stickyOffset`：

```swift
override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    stickyContainer.updateStickyOffset(headerBarHeight)
}
```

### 2. 子页面懒加载

在 `getCurrentScrollableChild()` 中，如果子视图还没加载，**必须先加载它**：

```swift
func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
    // ⚠️ 确保子视图已加载
    if worksVC == nil {
        worksVC = loadWorksVC()
    }
    return worksVC
}
```

### 3. 滚动回调绑定

子页面内部的 ScrollView 必须正确绑定滚动回调：

```swift
worksVC.onScrollEvent = { [weak self] scrollView in
    self?.onScrollEvent?(scrollView)  // 传递给容器
}
```

---

## 层级依赖关系

```
┌─────────────────────────────────────────────────────────────────┐
│                          App 层                                  │
│                    (AppDelegate, SceneDelegate)                  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│   Profile 模块     │ │  AssetFlow 模块    │ │    Common 模块    │
│   (组装层)         │ │  (业务模块)        │ │   (叶子节点)       │
└─────────┬─────────┘ └─────────┬─────────┘ └─────────┬─────────┘
          │                     │                     │
          └──────────┬──────────┴──────────┬──────────┘
                     ▼                     ▼
        ┌─────────────────────────────────────────────┐
        │               Components 层                  │
        │   (MenuView, StickyHeaderContainerView)     │
        └─────────────────────┬───────────────────────┘
                              ▼
        ┌─────────────────────────────────────────────┐
        │                  Core 层                     │
        │     (NestedScrollProtocol, Manager)         │
        │                                             │
        │  ⚠️ 只有 StickyContainer 依赖此层           │
        │  业务模块通过闭包回调，不直接依赖            │
        └─────────────────────────────────────────────┘
```

---

## 解耦收益

| 对比项 | 改造前 | 改造后 |
|--------|-------|--------|
| 业务模块依赖 | ❌ 直接依赖 NestedScrollManager | ✅ 仅依赖闭包类型 |
| 吸顶组件复用 | ❌ 与业务耦合 | ✅ 通用组件，可复用 |
| 独立发布 | ❌ 无法独立成 Pod | ✅ 可独立发布 |
| 单元测试 | ❌ 需要 Mock Manager | ✅ 只需 Mock 闭包 |
| 多团队协作 | ❌ 需要理解滚动管理 | ✅ 只需实现协议 |
| 可替换性 | ❌ 强绑定实现 | ✅ 可替换不同实现 |

---

## 组件化拆分建议

| 组件 | Pod/SPM 名称建议 | 说明 | 依赖 |
|------|-----------------|------|------|
| Core | `ProfileCore` | 嵌套滚动核心协议 | 无 |
| Components | `ProfileComponents` | 通用 UI 组件（含 StickyContainer） | Core |
| Profile | `ProfileContainer` | 个人页面容器框架 | Core, Components |
| AssetFlow/Protocol | `AssetFlowProtocol` | 资产流协议（接口层） | Core (仅协议类型) |
| AssetFlow/Modules/* | 各业务独立 Pod | 各团队独立维护 | Protocol |
| Common | `ProfileCommon` | 公共业务组件 | Core (仅协议类型) |

---

## 多团队协作

| 目录 | 负责团队 | 依赖说明 |
|------|---------|---------|
| `Core/` | 基础架构组 | 无外部依赖 |
| `Components/` | 基础架构组 | 依赖 Core |
| `Components/StickyContainer/` | 基础架构组 | 依赖 Core |
| `Profile/` | 个人页面组 | 组装层，依赖 Components |
| `AssetFlow/Protocol/` | 个人页面组 | 仅协议定义 |
| `AssetFlow/Modules/Appearance/` | 出境业务组 | 仅依赖 Protocol |
| `AssetFlow/Modules/Creation/` | 创作业务组 | 仅依赖 Protocol |
| `Common/` | 公共组件组 | 仅依赖 Core 协议类型 |
