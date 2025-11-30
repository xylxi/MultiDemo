# ProfileDemo - iOS 个人页面容器框架

## 最低支持版本

**iOS 13.0+**

## 架构设计

### 核心理念

`ProfileViewController` 是一个**容器页面**，职责分离：
- **ProfileViewController**：只负责用户信息头部 + 容器框架
- **资产流模块**：由外部通过协议注入，支持多人协作开发

### 项目结构

```
ProfileDemo/
├── 协议层
│   ├── AssetFlowProtocol.swift      # 资产流协议规范
│   └── NestedScrollProtocol.swift   # 嵌套滚动协议
│
├── 容器层
│   ├── ProfileViewController.swift   # 个人页面容器
│   ├── AssetFlowContainerView.swift  # 资产流容器视图
│   └── ProfileHeaderView.swift       # 用户信息头部
│
├── 组件层
│   ├── MenuView.swift               # 分类菜单组件
│   └── WorksFlowViewController.swift # 作品流（叶子节点）
│
├── 业务模块层（由不同开发者负责）
│   ├── AppearanceViewController.swift # 出境模块（开发者 A）
│   └── CreationViewController.swift   # 创作模块（开发者 B）
│
└── AppDelegate.swift                 # 使用示例
```

## 协议规范

### AssetFlowPageProtocol

每个资产流模块必须实现此协议：

```swift
public protocol AssetFlowPageProtocol: UIViewController {
    /// 获取当前可滚动的子视图（用于嵌套滚动联动）
    func getCurrentScrollableChild() -> NestedScrollChildProtocol?
    
    /// 设置嵌套滚动管理器
    func setScrollManager(_ manager: NestedScrollManager?)
    
    /// 获取内部所有水平滚动的 CollectionView（用于手势排除）
    func getAllHorizontalScrollViews() -> [UIScrollView]
}
```

### AssetFlowDataSource

外部通过实现此协议注入资产流配置：

```swift
public protocol AssetFlowDataSource: AnyObject {
    func assetFlowConfigs() -> [AssetFlowConfig]
}
```

### AssetFlowConfig

配置单个资产流模块：

```swift
public struct AssetFlowConfig {
    let title: String                           // 菜单标题
    let pageFactory: () -> AssetFlowPageProtocol // 懒加载工厂
}
```

## 使用方式

### 1. 创建 ProfileViewController

```swift
let profileVC = ProfileViewController()

// 配置用户信息
profileVC.configureProfile(UserProfile(...))
```

### 2. 实现数据源

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

### 3. 注入数据源

```swift
profileVC.assetFlowDataSource = MyAssetFlowDataSource()
```

## 开发新模块

### 步骤 1：创建 ViewController

```swift
class MyModuleViewController: UIViewController, AssetFlowPageProtocol {
    
    private weak var scrollManager: NestedScrollManager?
    
    // MARK: - AssetFlowPageProtocol
    
    func getCurrentScrollableChild() -> NestedScrollChildProtocol? {
        // 返回当前可滚动的子视图
    }
    
    func setScrollManager(_ manager: NestedScrollManager?) {
        self.scrollManager = manager
    }
    
    func getAllHorizontalScrollViews() -> [UIScrollView] {
        // 返回所有水平滚动的 CollectionView
        return [myPageCollectionView]
    }
}
```

### 步骤 2：在数据源中注册

```swift
AssetFlowConfig(title: "我的模块") {
    let vc = MyModuleViewController()
    vc.setScrollManager(scrollManager)
    return vc
}
```

## 懒加载验证

运行应用，观察控制台日志：

```
[ProfileViewController] 懒加载资产流页面: 出境
[AppearanceViewController] viewDidLoad - 出境模块已加载
[AppearanceViewController] 懒加载: 出境 > 作品

# 滑动到"创作"后
[ProfileViewController] 懒加载资产流页面: 创作
[CreationViewController] viewDidLoad - 创作模块已加载
[CreationViewController] 懒加载: 创作 > 发布

# 在"创作"中滑动到"资产"后
[CreationViewController] 懒加载: 创作 > 资产 (三级分类)
[AssetsViewController] viewDidLoad - 资产模块已加载
[AssetsViewController] 懒加载: 创作 > 资产 > 全部
```

## 视图层级

```
ProfileViewController
├── HeaderBar (固定顶部)
├── MainScrollView (外层滚动)
│   ├── ProfileHeaderView (用户信息 - ProfileVC 负责)
│   └── AssetFlowContainerView (资产流 - 外部注入)
│       ├── MenuView (一级分类菜单)
│       └── PageCollectionView (懒加载容器)
│           ├── AppearanceViewController (出境)
│           │   ├── MenuView
│           │   └── PageCollectionView
│           │       └── WorksFlowViewController...
│           └── CreationViewController (创作)
│               ├── MenuView
│               └── PageCollectionView
│                   ├── WorksFlowViewController (发布)
│                   ├── AssetsViewController (资产 - 三级)
│                   └── WorksFlowViewController (喜欢)
```

## 多人协作

| 区域 | 负责人 | 文件 |
|------|--------|------|
| 容器框架 | 主开发 | ProfileViewController, AssetFlowContainerView |
| 用户信息 | 主开发 | ProfileHeaderView |
| 出境模块 | 开发者 A | AppearanceViewController |
| 创作模块 | 开发者 B | CreationViewController |
| 公共组件 | 主开发 | MenuView, WorksFlowViewController |
