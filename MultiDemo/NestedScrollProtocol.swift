import UIKit

// MARK: - 嵌套滚动子视图协议
protocol NestedScrollChildProtocol: AnyObject {
    /// 子视图的 scrollView
    var childScrollView: UIScrollView { get }
    
    /// 是否允许子视图滚动
    var canChildScroll: Bool { get set }
}

// MARK: - 嵌套滚动父视图协议
protocol NestedScrollParentProtocol: AnyObject {
    /// 父视图是否可以滚动
    var canParentScroll: Bool { get set }
    
    /// 头部视图的高度（需要滚动隐藏的部分）
    var headerHeight: CGFloat { get }
    
    /// 吸顶偏移量（HeaderBar 高度，始终显示的部分）
    var stickyOffset: CGFloat { get }
    
    /// 父视图的 scrollView
    var parentScrollView: UIScrollView { get }
}

// MARK: - 滚动管理器
class NestedScrollManager: NSObject {
    
    weak var parentController: (UIViewController & NestedScrollParentProtocol)?
    
    weak var currentChild: NestedScrollChildProtocol? {
        didSet {
            guard oldValue !== currentChild else { return }
            
            // 重置旧的子视图
//            oldValue?.canChildScroll = false
//            oldValue?.childScrollView.contentOffset = .zero
            
            // 检查是否需要允许新子视图滚动
            if let parent = parentController {
                let maxOffset = parent.headerHeight
                let currentOffset = parent.parentScrollView.contentOffset.y
                
                if currentOffset >= maxOffset - 1 { // 添加 1pt 容差
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
            // 父视图不允许滚动，固定在最大偏移量
            scrollView.contentOffset.y = maxOffset
            return
        }
        
        // 父视图滚动到最大偏移量时
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
            // 子视图不允许滚动，固定在顶部
            scrollView.contentOffset.y = 0
            return
        }
        
        // 子视图滚动到顶部时
        if offsetY <= 0 {
            scrollView.contentOffset.y = 0
            child.canChildScroll = false
            parent.canParentScroll = true
        }
    }
}
