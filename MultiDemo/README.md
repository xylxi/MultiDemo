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
│   │   └── AssetFlowContainerView.swift    # 资产流容器视图
│   └── Modules/                            # 业务子模块（各团队独立开发）
│       ├── Appearance/
│       │   └── AppearanceViewController.swift  # 出境模块
│       └── Creation/
│           └── CreationViewController.swift    # 创作模块
│
└── Common/                                 # 公共业务组件
    └── WorksFlowViewController.swift       # 作品流列表（叶子节点）
```

## 组件化说明

### 层级依赖关系（解耦后）

```
┌─────────────────────────────────────────────────────────────────┐
│                          App 层                                  │
│                    (AppDelegate, SceneDelegate)                  │
│                         组装依赖                                  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│   Profile 模块     │ │  AssetFlow 模块    │ │    Common 模块    │
│                   │ │                   │ │                   │
│ ProfileVC         │ │ Container         │ │ WorksFlowVC       │
│ (组装层：绑定闭包) │ │ Modules/          │ │ (叶子节点)         │
│                   │ │                   │ │                   │
│ 定义：            │ │ 实现：             │ │ 不依赖任何         │
│ - 无直接依赖      │ │ AssetFlowPage     │ │ 业务模块           │
│   AssetFlow 实现  │ │ Protocol          │ │                   │
└─────────┬─────────┘ └─────────┬─────────┘ └─────────┬─────────┘
          │                     │                     │
          └──────────┬──────────┴──────────┬──────────┘
                     ▼                     ▼
        ┌─────────────────────────────────────────────┐
        │               Components 层                  │
        │             (MenuView, etc.)                 │
        └─────────────────────┬───────────────────────┘
                              ▼
        ┌─────────────────────────────────────────────┐
        │                  Core 层                     │
        │     (NestedScrollProtocol, Manager)         │
        │                                             │
        │  ⚠️ 只有 ProfileVC（组装层）依赖此层         │
        │  业务模块通过闭包回调，不直接依赖            │
        └─────────────────────────────────────────────┘
```

### 解耦设计：闭包回调模式

```
┌─────────────────────────────────────────────────────────────────┐
│                    数据流向（闭包回调）                           │
└─────────────────────────────────────────────────────────────────┘

ProfileViewController (组装层)
        │
        │  setScrollCallbacks(onScroll:, onChildChanged:)
        ▼
AssetFlowPageProtocol 实现类
(AppearanceVC / CreationVC)
        │
        │  worksVC.onScrollEvent = { ... }
        ▼
WorksFlowViewController (叶子节点)
        │
        │  scrollViewDidScroll → onScrollEvent?(scrollView)
        ▼
ProfileViewController 接收 → scrollManager.handleChildScroll()


优点：
✅ 业务模块不需要 import Core 层
✅ 完全解耦，便于独立开发和测试
✅ 可替换不同的滚动管理实现
```

### 组件化拆分建议

| 组件 | Pod/SPM 名称建议 | 说明 | 依赖 |
|------|-----------------|------|------|
| Core | `ProfileCore` | 嵌套滚动核心协议 | 无 |
| Components | `ProfileComponents` | 通用 UI 组件 | Core |
| Profile | `ProfileContainer` | 个人页面容器框架 | Core, Components |
| AssetFlow/Protocol | `AssetFlowProtocol` | 资产流协议（接口层） | Core (仅协议类型) |
| AssetFlow/Container | `AssetFlowContainer` | 资产流容器实现 | Protocol, Components |
| AssetFlow/Modules/* | 各业务独立 Pod | 各团队独立维护 | Protocol |
| Common | `ProfileCommon` | 公共业务组件 | Core (仅协议类型) |

## 协议规范

### 闭包类型定义

```swift
/// 子视图滚动事件回调
public typealias ScrollEventHandler = (UIScrollView) -> Void

/// 当前子视图变更回调
public typealias CurrentChildChangedHandler = (NestedScrollChildProtocol) -> Void
```

### AssetFlowPageProtocol

每个资产流模块必须实现：

```swift
public protocol AssetFlowPageProtocol: UIViewController {
    
    /// 获取当前可滚动的子视图
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    
    /// 设置滚动事件回调（解耦方式）
    func setScrollCallbacks(onScroll: @escaping ScrollEventHandler, 
                            onChildChanged: @escaping CurrentChildChangedHandler)
    
    /// 获取内部所有水平滚动的 CollectionView（用于手势排除）
    func getAllHorizontalScrollViews() -> [UIScrollView]
}
```

### NestedScrollChildProtocol

叶子节点（WorksFlowViewController）实现：

```swift
public protocol NestedScrollChildProtocol: AnyObject {
    var childScrollView: UIScrollView { get }
    var canChildScroll: Bool { get set }
}
```

### AssetFlowDataSource

外部注入资产流配置：

```swift
public protocol AssetFlowDataSource: AnyObject {
    func assetFlowConfigs() -> [AssetFlowConfig]
}
```

## 使用示例

```swift
// 1. 创建 ProfileViewController
let profileVC = ProfileViewController()

// 2. 配置用户信息
profileVC.configureProfile(UserProfile(...))

// 3. 注入资产流数据源
profileVC.assetFlowDataSource = MyAssetFlowDataSource()

// ProfileViewController 内部会：
// - 创建 AssetFlowPage 实例
// - 绑定闭包回调，连接 NestedScrollManager
// - 业务模块无需关心滚动管理细节
```

## 新增资产流模块

1. 在 `AssetFlow/Modules/` 下创建新目录
2. 实现 `AssetFlowPageProtocol` 协议
3. 在 `AssetFlowDataSource` 中注册

```swift
// AssetFlow/Modules/NewModule/NewModuleViewController.swift
class NewModuleViewController: UIViewController, AssetFlowPageProtocol {
    
    private var onScrollEvent: ScrollEventHandler?
    private var onCurrentChildChanged: CurrentChildChangedHandler?
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        return currentWorksVC
    }
    
    func setScrollCallbacks(onScroll: @escaping ScrollEventHandler,
                            onChildChanged: @escaping CurrentChildChangedHandler) {
        self.onScrollEvent = onScroll
        self.onCurrentChildChanged = onChildChanged
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        return [pageCollectionView]
    }
    
    // 在加载子页面时绑定闭包
    private func loadPage(at index: Int) -> WorksFlowViewController {
        let worksVC = WorksFlowViewController(...)
        worksVC.onScrollEvent = { [weak self] scrollView in
            self?.onScrollEvent?(scrollView)
        }
        // ...
        return worksVC
    }
}

// 注册
AssetFlowConfig(title: "新模块") {
    return NewModuleViewController()
}
```

## 多团队协作

| 目录 | 负责团队 | 依赖说明 |
|------|---------|---------|
| `Core/` | 基础架构组 | 无外部依赖 |
| `Components/` | 基础架构组 | 依赖 Core |
| `Profile/` | 个人页面组 | 组装层，依赖所有模块 |
| `AssetFlow/Protocol/` | 个人页面组 | 仅协议定义 |
| `AssetFlow/Container/` | 个人页面组 | 依赖 Protocol, Components |
| `AssetFlow/Modules/Appearance/` | 出境业务组 | 仅依赖 Protocol |
| `AssetFlow/Modules/Creation/` | 创作业务组 | 仅依赖 Protocol |
| `Common/` | 公共组件组 | 仅依赖 Core 协议类型 |

## 解耦收益

| 对比项 | 改造前 | 改造后 |
|--------|-------|--------|
| 业务模块依赖 | ❌ 直接依赖 NestedScrollManager | ✅ 仅依赖闭包类型 |
| 独立发布 | ❌ 无法独立成 Pod | ✅ 可独立发布 |
| 单元测试 | ❌ 需要 Mock Manager | ✅ 只需 Mock 闭包 |
| 多团队协作 | ❌ 需要理解滚动管理 | ✅ 只需实现协议 |
| 可替换性 | ❌ 强绑定实现 | ✅ 可替换不同实现 |
