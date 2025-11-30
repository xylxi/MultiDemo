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
│   │   └── ProfileViewController.swift     # 个人页面容器
│   └── Header/
│       └── ProfileHeaderView.swift         # 用户信息头部 + HeaderBar
│
├── AssetFlow/                              # 资产流模块（可独立成 Pod/SPM）
│   ├── Protocol/
│   │   └── AssetFlowProtocol.swift         # 资产流协议规范
│   ├── Container/
│   │   └── AssetFlowContainerView.swift    # 资产流容器视图
│   └── Modules/                            # 业务子模块（各团队独立开发）
│       ├── Appearance/
│       │   └── AppearanceViewController.swift  # 出境模块
│       └── Creation/
│           └── CreationViewController.swift    # 创作模块
│
└── Common/                                 # 公共业务组件
    └── WorksFlowViewController.swift       # 作品流列表
```

## 组件化说明

### 层级依赖关系

```
┌─────────────────────────────────────────────────────────┐
│                        App 层                           │
│              (AppDelegate, SceneDelegate)               │
└─────────────────────────┬───────────────────────────────┘
                          │ 依赖
┌─────────────────────────▼───────────────────────────────┐
│                     Profile 模块                         │
│         (ProfileViewController, ProfileHeaderView)       │
└─────────────────────────┬───────────────────────────────┘
                          │ 依赖
┌─────────────────────────▼───────────────────────────────┐
│                    AssetFlow 模块                        │
│     (AssetFlowProtocol, AssetFlowContainerView)         │
├─────────────────────────────────────────────────────────┤
│  Modules/          │  Modules/          │  Modules/     │
│  Appearance/       │  Creation/         │  ...          │
│  (开发者 A)         │  (开发者 B)         │  (开发者 N)   │
└─────────────────────────┬───────────────────────────────┘
                          │ 依赖
┌─────────────────────────▼───────────────────────────────┐
│                    Components 层                         │
│              (MenuView, PageContainer)                   │
└─────────────────────────┬───────────────────────────────┘
                          │ 依赖
┌─────────────────────────▼───────────────────────────────┐
│                       Core 层                            │
│      (NestedScrollProtocol, NestedScrollManager)        │
└─────────────────────────────────────────────────────────┘
```

### 组件化拆分建议

| 组件 | Pod/SPM 名称建议 | 说明 |
|------|-----------------|------|
| Core | `ProfileCore` | 嵌套滚动核心协议 |
| Components | `ProfileComponents` | 通用 UI 组件 |
| Profile | `ProfileContainer` | 个人页面容器框架 |
| AssetFlow/Protocol | `AssetFlowProtocol` | 资产流协议（接口层） |
| AssetFlow/Container | `AssetFlowContainer` | 资产流容器实现 |
| AssetFlow/Modules/* | 各业务独立 Pod | 各团队独立维护 |
| Common | `ProfileCommon` | 公共业务组件 |

## 协议规范

### AssetFlowPageProtocol

每个资产流模块必须实现：

```swift
public protocol AssetFlowPageProtocol: UIViewController {
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    func setScrollManager(_ manager: NestedScrollManager?)
    func getAllHorizontalScrollViews() -> [UIScrollView]
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
```

## 新增资产流模块

1. 在 `AssetFlow/Modules/` 下创建新目录
2. 实现 `AssetFlowPageProtocol` 协议
3. 在 `AssetFlowDataSource` 中注册

```swift
// AssetFlow/Modules/NewModule/NewModuleViewController.swift
class NewModuleViewController: UIViewController, AssetFlowPageProtocol {
    // 实现协议方法...
}

// 注册
AssetFlowConfig(title: "新模块") {
    return NewModuleViewController()
}
```

## 多团队协作

| 目录 | 负责团队 |
|------|---------|
| `Core/` | 基础架构组 |
| `Components/` | 基础架构组 |
| `Profile/` | 个人页面组 |
| `AssetFlow/Protocol/` | 个人页面组 |
| `AssetFlow/Container/` | 个人页面组 |
| `AssetFlow/Modules/Appearance/` | 出境业务组 |
| `AssetFlow/Modules/Creation/` | 创作业务组 |
| `Common/` | 公共组件组 |
