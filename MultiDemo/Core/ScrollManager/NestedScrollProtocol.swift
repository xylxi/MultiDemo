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
    
    public weak var parentController: (UIViewController & NestedScrollParentProtocol)?
    
    public weak var currentChild: NestedScrollChildProtocol? {
        didSet {
            guard oldValue !== currentChild else { return }
            
            // 检查是否需要允许新子视图滚动
            if let parent = parentController {
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
    
    /// 处理父视图滚动
    public func handleParentScroll(_ scrollView: UIScrollView) {
        guard let parent = parentController else { return }
        
        let offsetY = scrollView.contentOffset.y
        let maxOffset = parent.headerHeight
        
        if !parent.canParentScroll {
            scrollView.contentOffset.y = maxOffset
            return
        }
        
        if offsetY >= maxOffset {
            scrollView.contentOffset.y = maxOffset
            parent.canParentScroll = false
            currentChild?.canChildScroll = true
        }
    }
    
    /// 处理子视图滚动
    public func handleChildScroll(_ scrollView: UIScrollView) {
        guard let parent = parentController,
              let child = currentChild else { return }
        
        let offsetY = scrollView.contentOffset.y
        
        if !child.canChildScroll {
            scrollView.contentOffset.y = 0
            return
        }
        
        if offsetY <= 0 {
            scrollView.contentOffset.y = 0
            child.canChildScroll = false
            parent.canParentScroll = true
        }
    }
}
