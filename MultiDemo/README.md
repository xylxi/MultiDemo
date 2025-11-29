# ProfileDemo - iOS 多级分类吸顶个人页面

## 项目结构

```
ProfileDemo/
├── AppDelegate.swift                 # App 入口
├── NestedScrollProtocol.swift       # 嵌套滚动协议与管理器
├── MenuView.swift                   # 分类菜单视图组件
├── WorksFlowViewController.swift    # 作品流展示（叶子节点）
├── PageContainerViewController.swift # 分页容器（水平切换）
├── CategoryContainerViewController.swift # 分类容器（菜单+分页）
├── ProfileHeaderView.swift          # 用户信息头部视图
├── ProfileHeaderBar.swift           # 顶部导航栏
└── ProfileViewController.swift      # 主控制器
```

## 层级结构

```
ProfileViewController
├── HeaderBar (固定在顶部)
├── MainScrollView (外层滚动)
│   ├── ProfileHeaderView (用户信息，30%区域)
│   ├── StickyMenuView (一级分类菜单：出境、创作)
│   └── CategoryContainerViewController (一级分类容器)
│       └── PageContainerViewController
│           ├── [出境] CategoryContainerViewController
│           │   ├── MenuView (作品、喜欢、点赞)
│           │   └── PageContainerViewController
│           │       ├── WorksFlowViewController (作品)
│           │       ├── WorksFlowViewController (喜欢)
│           │       └── WorksFlowViewController (点赞)
│           └── [创作] CategoryContainerViewController
│               ├── MenuView (发布、资产、喜欢)
│               └── PageContainerViewController
│                   ├── WorksFlowViewController (发布)
│                   ├── [资产] CategoryContainerViewController
│                   │   ├── MenuView (全部、图片、视频、收藏)
│                   │   └── PageContainerViewController
│                   │       ├── WorksFlowViewController (全部)
│                   │       ├── WorksFlowViewController (图片)
│                   │       ├── WorksFlowViewController (视频)
│                   │       └── WorksFlowViewController (收藏)
│                   └── WorksFlowViewController (喜欢)
```

## 核心功能

### 1. 嵌套滚动 (NestedScrollProtocol)
- `NestedScrollParentProtocol`: 父视图滚动协议
- `NestedScrollChildProtocol`: 子视图滚动协议  
- `NestedScrollManager`: 统一管理父子滚动状态

### 2. 吸顶效果
- 滚动时用户信息区域逐渐隐藏
- 一级分类菜单悬停在 HeaderBar 底部
- HeaderBar 背景随滚动渐变显示

### 3. 多级分类切换
- 支持无限级分类嵌套
- 每级分类都有独立的菜单和分页容器
- 左右滑动或点击菜单切换分类

### 4. 作品流展示
- 一行三个 Cell 的网格布局
- 使用不同颜色区分不同分类
- 显示完整的分类路径

## 使用方法

### Xcode 项目集成

1. 创建新的 iOS 项目 (App)
2. 删除默认的 ViewController.swift 和 Main.storyboard
3. 将所有 .swift 文件拖入项目
4. 在 Info.plist 中删除 `UIMainStoryboardFile` 和 `UISceneStoryboardFile` 键
5. 运行项目

### 配置分类数据

在 `ProfileViewController.swift` 中修改 `categories` 数组：

```swift
private lazy var categories: [CategoryItem] = {
    return [
        CategoryItem(
            title: "分类名称",
            color: .systemBlue,
            subCategories: [
                CategoryItem(title: "子分类1", color: .systemRed),
                CategoryItem(title: "子分类2", color: .systemGreen)
            ]
        )
    ]
}()
```

## 关键实现细节

### 滚动同步机制

```
1. 外层 ScrollView 滚动时：
   - 未到达吸顶点：正常滚动
   - 到达吸顶点：锁定位置，允许子视图滚动

2. 内层 CollectionView 滚动时：
   - offset > 0：正常滚动
   - offset <= 0：锁定位置，允许父视图滚动
```

### 分类切换时的滚动状态重置

切换分类时，`NestedScrollManager` 会自动更新当前激活的子视图引用，确保滚动状态正确同步。

## 注意事项

1. 确保 iOS 15.0+ 部署目标
2. 作品流数据为 Mock 数据，实际使用时需替换为真实数据源
3. 可根据需要调整 HeaderBar 高度、菜单高度等常量
