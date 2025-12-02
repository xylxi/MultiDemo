import UIKit

// MARK: - ================== 嵌套滚动协议 ==================

// MARK: - 嵌套滚动子视图协议
/// 作为嵌套滚动的子视图需要实现此协议
public protocol NestedScrollChildProtocol: AnyObject {
    
    /// 子视图的 ScrollView
    var childScrollView: UIScrollView { get }
    
    /// 是否允许子视图滚动
    var canChildScroll: Bool { get set }
}

// MARK: - 嵌套滚动容器协议（约定大于配置）
/// 容器实现此协议，子视图通过响应链自动查找并注册
/// 
/// 使用方式：
/// 1. 容器（如 StickyHeaderContainerView）实现此协议
/// 2. 叶子节点（如 WorksFlowViewController）在 viewDidAppear 时调用 findNestedScrollContainer() 自动注册
/// 3. 叶子节点在 scrollViewDidScroll 时调用 container.handleChildScroll() 通知容器
/// 
/// 优点：无需层层传递闭包，子视图自动发现并注册到最近的容器
public protocol NestedScrollContainerProtocol: AnyObject {
    
    /// 注册可滚动的子视图（子视图在 viewDidAppear 时自动调用）
    func registerScrollableChild(_ child: NestedScrollChildProtocol)
    
    /// 处理子视图滚动事件（子视图在 scrollViewDidScroll 时自动调用）
    func handleChildScroll(_ scrollView: UIScrollView)
}

// MARK: - 响应链扩展
public extension UIResponder {
    
    /// 沿响应链向上查找实现了 NestedScrollContainerProtocol 的容器
    /// 
    /// 使用示例：
    /// ```swift
    /// override func viewDidAppear(_ animated: Bool) {
    ///     super.viewDidAppear(animated)
    ///     if let container = view.findNestedScrollContainer() {
    ///         container.registerScrollableChild(self)
    ///     }
    /// }
    /// ```
    /// 
    /// - Returns: 最近的嵌套滚动容器，如果没有则返回 nil
    func findNestedScrollContainer() -> NestedScrollContainerProtocol? {
        var responder: UIResponder? = self
        while let r = responder {
            if let container = r as? NestedScrollContainerProtocol {
                return container
            }
            responder = r.next
        }
        return nil
    }
}

// MARK: - 嵌套滚动父视图协议
/// 作为嵌套滚动的父视图需要实现此协议
public protocol NestedScrollParentProtocol: AnyObject {
    
    /// 父视图是否可以滚动
    var canParentScroll: Bool { get set }
    
    /// 头部视图的高度（需要滚动隐藏的部分）
    var headerHeight: CGFloat { get }
    
    /// 吸顶偏移量（始终显示的部分高度）
    var stickyOffset: CGFloat { get }
    
    /// 父视图的 ScrollView
    var parentScrollView: UIScrollView { get }
}

// MARK: - 支持手势排除的 ScrollView
/// 支持配置排除特定视图的手势同时识别
public class NestedParentScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    /// 排除的视图列表（这些视图的手势不会与父 ScrollView 同时识别）
    public var excludeSuperViews = [UIView]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.bounces = true
        self.alwaysBounceVertical = true
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 添加需要排除的视图
    public func addExcludeSuperView(_ view: UIView) {
        if !excludeSuperViews.contains(where: { $0 === view }) {
            excludeSuperViews.append(view)
        }
    }
    
    /// 移除排除的视图
    public func removeExcludeSuperView(_ view: UIView) {
        excludeSuperViews.removeAll { $0 === view }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // 检查另一个手势的视图是否就是排除列表中的视图
        if let view = otherGestureRecognizer.view {
            for excludeView in excludeSuperViews {
                if view === excludeView {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - 嵌套滚动管理器
/// 管理父子视图之间的滚动状态切换
public class NestedScrollManager: NSObject {
    
    /// 父容器（可以是 ViewController 或 View）
    public weak var parentController: (UIViewController & NestedScrollParentProtocol)?
    
    /// 父容器视图（用于 StickyHeaderContainerView 等纯 View 场景）
    public weak var parentView: (UIView & NestedScrollParentProtocol)?
    
    /// 获取父容器协议实现
    private var parent: NestedScrollParentProtocol? {
        return parentController ?? parentView
    }
    
    /// 子视图的锁定 offset（切换子视图时保存，用于保持子视图滚动位置）
    private var lockedOffsets: [ObjectIdentifier: CGFloat] = [:]
    
    public weak var currentChild: NestedScrollChildProtocol? {
        didSet {
            guard oldValue !== currentChild else { return }
            
            // 保存旧子视图的 offset
            if let oldChild = oldValue {
                let scrollViewId = ObjectIdentifier(oldChild.childScrollView)
                let currentOffset = oldChild.childScrollView.contentOffset.y
                lockedOffsets[scrollViewId] = max(0, currentOffset)
            }
            
            // 检查是否需要允许新子视图滚动
            if let parent = parent {
                let maxOffset = parent.headerHeight
                let currentOffset = parent.parentScrollView.contentOffset.y
                
                if currentOffset >= maxOffset - 1 {
                    currentChild?.canChildScroll = true
                    parent.canParentScroll = false
                } else {
                    currentChild?.canChildScroll = false
                }
            }
        }
    }
    
    public override init() {
        super.init()
    }
    
    /// 处理父视图滚动
    public func handleParentScroll(_ scrollView: UIScrollView) {
        guard let parent = parent else { return }
        
        let offsetY = scrollView.contentOffset.y
        let maxOffset = parent.headerHeight
        
        if !parent.canParentScroll {
            scrollView.contentOffset.y = maxOffset
            return
        }
        
        // 限制 contentOffset.y 在 [0, maxOffset] 范围内
        if offsetY < 0 {
            scrollView.contentOffset.y = 0
        } else if offsetY >= maxOffset {
            scrollView.contentOffset.y = maxOffset
            parent.canParentScroll = false
            currentChild?.canChildScroll = true
        }
    }
    
    /// 处理子视图滚动
    public func handleChildScroll(_ scrollView: UIScrollView) {
        guard let parent = parent,
              let child = currentChild else { return }
        
        let offsetY = scrollView.contentOffset.y
        let scrollViewId = ObjectIdentifier(scrollView)
        let parentOffset = parent.parentScrollView.contentOffset.y
        let maxOffset = parent.headerHeight
        
        // 获取锁定的 offset，首次记录当前值
        let lockedOffset: CGFloat
        if let saved = lockedOffsets[scrollViewId] {
            lockedOffset = saved
        } else {
            lockedOffset = max(0, offsetY)
            lockedOffsets[scrollViewId] = lockedOffset
        }
        
        // 判断 parent 位置
        let parentAtTop = parentOffset <= 0
        let parentAtMax = parentOffset >= maxOffset - 1
        
        // Case 1: parent 在中间位置 (0 < offset < maxOffset)，child 完全锁定
        if !parentAtTop && !parentAtMax {
            scrollView.contentOffset.y = lockedOffset
            return
        }
        
        // Case 2: parent 在顶部 (offset == 0)，只允许 child 向下滚动（offset 减少）
        if parentAtTop && !parentAtMax {
            if offsetY > lockedOffset {
                // 用户想向上滚动（增加 offset），锁定 child，让 parent 响应
                scrollView.contentOffset.y = lockedOffset
                return
            }
            // 允许向下滚动（减少 offset），不强制设为 0 以保留 bounces 效果
            lockedOffsets[scrollViewId] = max(0, offsetY)
            return
        }
        
        // Case 3: parent 在吸顶位置 (offset == maxOffset)，child 可以双向滚动
        if parentAtMax {
            if offsetY <= 0 {
                // child 到顶了，切换到 parent 滚动
                scrollView.contentOffset.y = 0
                child.canChildScroll = false
                parent.canParentScroll = true
                lockedOffsets[scrollViewId] = 0
            } else {
                // 更新锁定值
                lockedOffsets[scrollViewId] = offsetY
            }
        }
    }
}

