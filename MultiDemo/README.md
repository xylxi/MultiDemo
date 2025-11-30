# ProfileDemo - iOS 多级分类吸顶个人页面

## 最低支持版本

**iOS 13.0+**

## 项目结构

```
ProfileDemo/
├── AppDelegate.swift                 # App 入口
├── NestedScrollProtocol.swift       # 嵌套滚动协议与管理器
├── CategoryPageProtocol.swift       # 分类页面协议与懒加载管理器
├── MenuView.swift                   # 分类菜单视图组件
├── PageContainerViewController.swift # 分页容器（支持懒加载）
├── WorksFlowViewController.swift    # 作品流展示（叶子节点）
├── ProfileHeaderView.swift          # 用户信息头部视图
├── ProfileHeaderBar.swift           # 顶部导航栏
├── ProfileViewController.swift      # 主容器页面
├── AppearanceViewController.swift   # 出境模块（开发者 A）
└── CreationViewController.swift     # 创作模块（开发者 B）
```

## 架构设计

### 容器化设计

个人页面采用容器化架构，支持多人协作开发：

```
ProfileViewController (容器)
├── HeaderBar
├── ProfileHeaderView (用户信息)
├── StickyMenuView (一级分类菜单)
└── PageContainerViewController (懒加载容器)
    ├── AppearanceViewController (出境模块 - 开发者 A)
    │   ├── MenuView
    │   └── PageContainerViewController
    │       ├── WorksFlowViewController (作品)
    │       ├── WorksFlowViewController (喜欢)
    │       └── WorksFlowViewController (点赞)
    └── CreationViewController (创作模块 - 开发者 B)
        ├── MenuView
        └── PageContainerViewController
            ├── WorksFlowViewController (发布)
            ├── AssetsViewController (资产 - 三级分类)
            │   ├── MenuView
            │   └── PageContainerViewController
            │       ├── WorksFlowViewController (全部)
            │       ├── WorksFlowViewController (图片)
            │       ├── WorksFlowViewController (视频)
            │       └── WorksFlowViewController (收藏)
            └── WorksFlowViewController (喜欢)
```

### 懒加载机制

1. **一级分类懒加载**：只有当用户滑动或点击到对应分类时，才创建 `AppearanceViewController` 或 `CreationViewController`
2. **二级/三级分类懒加载**：每个模块内部的子分类也是懒加载的
3. **日志输出**：每个 ViewController 创建时会打印日志，方便验证懒加载

### 分类页面协议

每个分类模块需要实现 `CategoryPageProtocol`：

```swift
protocol CategoryPageProtocol: UIViewController {
    static var categoryTitle: String { get }
    func getCurrentScrollChild() -> NestedScrollChildProtocol?
}
```

### 添加新分类模块

```swift
// 1. 创建新模块 ViewController
class NewModuleViewController: UIViewController, CategoryPageProtocol {
    static var categoryTitle: String { "新模块" }
    
    func getCurrentScrollChild() -> NestedScrollChildProtocol? {
        // 返回当前可滚动的子视图
    }
}

// 2. 在 ProfileViewController 中注册
let configs: [CategoryPageConfig] = [
    CategoryPageConfig(title: "出境") { ... },
    CategoryPageConfig(title: "创作") { ... },
    // 添加新模块
    CategoryPageConfig(title: "新模块") { [weak self] in
        let vc = NewModuleViewController()
        vc.setScrollManager(self?.scrollManager)
        return vc
    }
]
```

## 核心功能

### 1. 嵌套滚动

- `NestedParentScrollView`: 支持排除特定视图的手势同时识别
- `NestedScrollManager`: 管理父子视图的滚动状态切换

### 2. 吸顶效果

- 滚动时用户信息区域逐渐隐藏
- 一级分类菜单悬停在 HeaderBar 底部

### 3. 手势冲突处理

- 垂直滚动时不触发水平分页
- 水平滑动时不触发垂直滚动

## 多人协作

| 模块 | 负责人 | 文件 |
|------|--------|------|
| 容器页面 | 主开发 | ProfileViewController.swift |
| 出境模块 | 开发者 A | AppearanceViewController.swift |
| 创作模块 | 开发者 B | CreationViewController.swift |
| 公共组件 | 主开发 | MenuView, PageContainer, WorksFlow 等 |

## 验证懒加载

运行应用后，观察控制台日志：

1. 启动时只会看到 `ProfileViewController` 相关日志
2. 首次显示时创建第一个分类页面（出境）
3. 滑动到"创作"时才创建 `CreationViewController`
4. 在"创作"中滑动到"资产"时才创建 `AssetsViewController`
