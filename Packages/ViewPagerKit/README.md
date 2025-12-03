# ViewPagerKit

一个独立的 iOS ViewPager 组件库，类似 Android 的 ViewPager，实现 Tab + 横向分页滑动效果。

## 特性

- ✅ Tab 栏 + 页面双向联动
- ✅ 页面懒加载 & 缓存
- ✅ **智能内存管理**（多种缓存策略）
- ✅ 可自定义 Tab 栏样式
- ✅ 支持页面生命周期回调
- ✅ 滚动进度回调（可实现自定义动画）
- ✅ 指示器平滑过渡动画
- ✅ 纯 Swift 实现，无外部依赖（除 SnapKit）

## 安装

### Swift Package Manager

```swift
dependencies: [
    .package(path: "../Packages/ViewPagerKit")
]
```

## 使用方式

### 基础用法

```swift
import ViewPagerKit

class MyViewController: UIViewController {
    
    private lazy var viewPager: ViewPager = {
        let pager = ViewPager()
        pager.dataSource = self
        pager.delegate = self
        return pager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(viewPager)
        viewPager.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewPager.reloadData()
    }
}

// MARK: - ViewPagerDataSource
extension MyViewController: ViewPagerDataSource {
    
    func numberOfPages(in viewPager: ViewPager) -> Int {
        return 3
    }
    
    func viewPager(_ viewPager: ViewPager, titleForPageAt index: Int) -> String {
        return ["首页", "发现", "我的"][index]
    }
    
    func viewPager(_ viewPager: ViewPager, viewControllerForPageAt index: Int) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = [.systemRed, .systemGreen, .systemBlue][index]
        return vc
    }
}

// MARK: - ViewPagerDelegate
extension MyViewController: ViewPagerDelegate {
    
    func viewPager(_ viewPager: ViewPager, didScrollToPageAt index: Int) {
        print("切换到页面: \(index)")
    }
}
```

### 自定义配置

```swift
// ViewPager 配置
let config = ViewPagerConfig(
    tabBarHeight: 48,           // Tab 栏高度
    showTabBar: true,           // 是否显示 Tab 栏
    isScrollEnabled: true,      // 是否可滑动切换
    tabBarConfig: TabBarConfig( // Tab 栏样式配置
        normalColor: .gray,
        selectedColor: .black,
        indicatorColor: .systemBlue,
        indicatorHeight: 3
    )
)

let viewPager = ViewPager(config: config)
```

### 页面生命周期

实现 `ViewPagerPageProtocol` 可接收页面生命周期回调：

```swift
class MyPageViewController: UIViewController, ViewPagerPageProtocol {
    
    func pageWillAppear() {
        print("页面即将显示")
    }
    
    func pageDidAppear() {
        print("页面已显示")
    }
    
    func pageWillDisappear() {
        print("页面即将消失")
    }
    
    func pageDidDisappear() {
        print("页面已消失")
    }
}
```

### 滚动进度回调

可用于实现自定义的联动动画：

```swift
extension MyViewController: ViewPagerDelegate {
    
    func viewPager(_ viewPager: ViewPager, didScrollWithProgress progress: CGFloat, fromIndex: Int, toIndex: Int) {
        // 根据滚动进度做自定义动画
        print("从 \(fromIndex) 到 \(toIndex), 进度: \(progress)")
    }
}
```

## 🧠 内存管理

ViewPager 提供了 4 种页面缓存策略，可根据业务场景选择：

### 缓存策略

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| `.offscreenLimit(1)` | 只保留当前页 ± 1 页 | **推荐**，大多数场景 |
| `.cacheAll` | 缓存所有访问过的页面 | 页面少（3-5 个） |
| `.lru(maxCount: 3)` | LRU 算法，最多保留 N 页 | 页面多但需要快速切换 |
| `.noCache` | 不缓存，每次重新创建 | 内存敏感场景 |

### 使用方式

```swift
// 方式 1: 只保留前后各 1 页（默认，推荐）
let config = ViewPagerConfig(
    cachePolicy: .offscreenLimit(1)
)

// 方式 2: 保留前后各 2 页（滑动更流畅，但内存占用更高）
let config = ViewPagerConfig(
    cachePolicy: .offscreenLimit(2)
)

// 方式 3: 缓存所有页面（页面少时使用）
let config = ViewPagerConfig(
    cachePolicy: .cacheAll
)

// 方式 4: LRU 缓存，最多保留 5 个页面
let config = ViewPagerConfig(
    cachePolicy: .lru(maxCount: 5)
)

// 方式 5: 不缓存（内存最优）
let config = ViewPagerConfig(
    cachePolicy: .noCache
)
```

### 内存警告处理

```swift
override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // 清理缓存，但保留当前页面
    viewPager.clearCache(keepCurrent: true)
}
```

### 内存占用对比

假设有 10 个页面，每个页面占用 50MB 内存：

| 策略 | 最大内存占用 |
|------|-------------|
| `.cacheAll` | 500MB（所有页面） |
| `.offscreenLimit(1)` | 150MB（3 个页面） |
| `.lru(maxCount: 3)` | 150MB（3 个页面） |
| `.noCache` | 50MB（1 个页面） |

## API 参考

### ViewPager

| 属性/方法 | 说明 |
|----------|------|
| `dataSource` | 数据源代理 |
| `delegate` | 事件代理 |
| `config` | 配置选项（包含缓存策略） |
| `currentIndex` | 当前页面索引 |
| `currentViewController` | 当前页面 VC |
| `tabBar` | Tab 栏视图 |
| `collectionView` | 内部滚动视图 |
| `reloadData()` | 重新加载数据 |
| `scrollToPage(_:animated:)` | 滚动到指定页面 |
| `viewController(at:)` | 获取指定索引的 VC |
| `clearCache(keepCurrent:)` | 手动清理缓存 |

### ViewPagerDataSource

| 方法 | 说明 |
|------|------|
| `numberOfPages(in:)` | 返回页面数量 |
| `viewPager(_:titleForPageAt:)` | 返回页面标题 |
| `viewPager(_:viewControllerForPageAt:)` | 创建页面 VC |

### ViewPagerDelegate

| 方法 | 说明 |
|------|------|
| `viewPager(_:didScrollToPageAt:)` | 页面切换完成回调 |
| `viewPager(_:willScrollToPageAt:)` | 页面将要切换回调 |
| `viewPager(_:didScrollWithProgress:fromIndex:toIndex:)` | 滚动进度回调 |

## 架构图

```
┌─────────────────────────────────────────┐
│              ViewPager                   │
│  ┌─────────────────────────────────────┐ │
│  │      ViewPagerTabBar (Tab 栏)        │ │
│  │  ┌─────┬─────┬─────┐               │ │
│  │  │ Tab │ Tab │ Tab │               │ │
│  │  └─────┴─────┴─────┘               │ │
│  │        ▔▔▔ (指示器)                  │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │     UICollectionView (横向分页)       │ │
│  │  ┌───────┬───────┬───────┐         │ │
│  │  │ Page0 │ Page1 │ Page2 │  ←→     │ │
│  │  │ (VC)  │ (VC)  │ (VC)  │         │ │
│  │  └───────┴───────┴───────┘         │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## License

MIT

