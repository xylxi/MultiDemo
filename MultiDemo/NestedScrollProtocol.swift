import UIKit

// MARK: - 嵌套滚动子视图协议
protocol NestedScrollChildProtocol: AnyObject {
    var childScrollView: UIScrollView { get }
    var canChildScroll: Bool { get set }
}

// MARK: - 嵌套滚动父视图协议
protocol NestedScrollParentProtocol: AnyObject {
    var canParentScroll: Bool { get set }
    var headerHeight: CGFloat { get }
    var stickyOffset: CGFloat { get }
    var parentScrollView: UIScrollView { get }
}

// MARK: - 支持排除视图的父 ScrollView
public class NestedParentScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    /// 排除的父视图列表（这些视图的子视图手势不会同时识别）
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
                    // 是排除列表中的视图，不允许同时识别
                    return false
                }
            }
        }
        // 其他情况允许同时识别
        return true
    }
}

// MARK: - 滚动管理器
class NestedScrollManager: NSObject {
    
    weak var parentController: (UIViewController & NestedScrollParentProtocol)?
    
    weak var currentChild: NestedScrollChildProtocol? {
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
    func handleParentScroll(_ scrollView: UIScrollView) {
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
    func handleChildScroll(_ scrollView: UIScrollView) {
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
