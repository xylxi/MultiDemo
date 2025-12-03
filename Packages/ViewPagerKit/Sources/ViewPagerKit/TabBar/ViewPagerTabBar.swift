import UIKit
import SnapKit

// MARK: - ================== Tab 栏组件 ==================

// MARK: - Tab 项模型

/// Tab 项数据模型
public struct TabItem {
    public let title: String
    public var badge: String?
    
    public init(title: String, badge: String? = nil) {
        self.title = title
        self.badge = badge
    }
}

// MARK: - Tab 栏代理

public protocol ViewPagerTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: ViewPagerTabBar, didSelectItemAt index: Int)
}

// MARK: - Tab 栏配置

public struct TabBarConfig {
    /// 普通状态文字颜色
    public var normalColor: UIColor
    /// 选中状态文字颜色
    public var selectedColor: UIColor
    /// 普通状态字体
    public var normalFont: UIFont
    /// 选中状态字体
    public var selectedFont: UIFont
    /// 指示器颜色
    public var indicatorColor: UIColor
    /// 指示器高度
    public var indicatorHeight: CGFloat
    /// 指示器宽度（nil 表示自适应文字宽度）
    public var indicatorWidth: CGFloat?
    /// 指示器圆角
    public var indicatorCornerRadius: CGFloat
    /// 背景颜色
    public var backgroundColor: UIColor
    /// 内边距
    public var contentInset: UIEdgeInsets
    
    public init(
        normalColor: UIColor = .secondaryLabel,
        selectedColor: UIColor = .label,
        normalFont: UIFont = .systemFont(ofSize: 15, weight: .medium),
        selectedFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
        indicatorColor: UIColor = .label,
        indicatorHeight: CGFloat = 3,
        indicatorWidth: CGFloat? = 24,
        indicatorCornerRadius: CGFloat = 1.5,
        backgroundColor: UIColor = .systemBackground,
        contentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    ) {
        self.normalColor = normalColor
        self.selectedColor = selectedColor
        self.normalFont = normalFont
        self.selectedFont = selectedFont
        self.indicatorColor = indicatorColor
        self.indicatorHeight = indicatorHeight
        self.indicatorWidth = indicatorWidth
        self.indicatorCornerRadius = indicatorCornerRadius
        self.backgroundColor = backgroundColor
        self.contentInset = contentInset
    }
    
    public static let `default` = TabBarConfig()
}

// MARK: - Tab 栏视图

/// ViewPager 专用 Tab 栏
public class ViewPagerTabBar: UIView {
    
    // MARK: - Public Properties
    
    public weak var delegate: ViewPagerTabBarDelegate?
    
    /// Tab 选中回调（闭包方式）
    public var onItemSelected: ((Int) -> Void)?
    
    /// 配置
    public var config: TabBarConfig = .default {
        didSet { applyConfig() }
    }
    
    /// 当前选中索引
    public private(set) var selectedIndex: Int = 0
    
    // MARK: - Private Properties
    
    private var items: [TabItem] = []
    private var buttons: [UIButton] = []
    
    // MARK: - UI Components
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = config.indicatorCornerRadius
        return view
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    public convenience init(config: TabBarConfig) {
        self.init(frame: .zero)
        self.config = config
        applyConfig()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(stackView)
        addSubview(indicatorView)
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(config.contentInset.left)
            make.trailing.equalToSuperview().offset(-config.contentInset.right)
            make.bottom.equalToSuperview().offset(-4)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(config.indicatorHeight)
            if let width = config.indicatorWidth {
                make.width.equalTo(width)
            }
        }
        
        applyConfig()
    }
    
    private func applyConfig() {
        backgroundColor = config.backgroundColor
        indicatorView.backgroundColor = config.indicatorColor
        indicatorView.layer.cornerRadius = config.indicatorCornerRadius
        
        // 更新 stackView 内边距
        stackView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(config.contentInset.left)
            make.trailing.equalToSuperview().offset(-config.contentInset.right)
        }
        
        // 更新按钮样式
        buttons.enumerated().forEach { index, button in
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? config.selectedColor : config.normalColor, for: .normal)
            button.titleLabel?.font = isSelected ? config.selectedFont : config.normalFont
        }
    }
    
    // MARK: - Public Methods
    
    /// 配置 Tab 项
    public func configure(with items: [TabItem]) {
        self.items = items
        
        // 清除旧按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        
        // 创建新按钮
        for (index, item) in items.enumerated() {
            let button = createButton(for: item, at: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        // 初始化指示器
        if !items.isEmpty {
            layoutIfNeeded()
            selectItem(at: 0, animated: false)
        }
    }
    
    /// 选中指定 Tab
    public func selectItem(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < buttons.count else { return }
        
        selectedIndex = index
        
        // 更新按钮状态
        buttons.enumerated().forEach { i, button in
            let isSelected = i == index
            button.setTitleColor(isSelected ? config.selectedColor : config.normalColor, for: .normal)
            button.titleLabel?.font = isSelected ? config.selectedFont : config.normalFont
        }
        
        // 更新指示器位置
        let selectedButton = buttons[index]
        
        indicatorView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(config.indicatorHeight)
            if let width = config.indicatorWidth {
                make.width.equalTo(width)
            } else {
                // 自适应文字宽度
                make.width.equalTo(selectedButton.titleLabel?.intrinsicContentSize.width ?? 24)
            }
            make.centerX.equalTo(selectedButton)
        }
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
    
    /// 根据滚动进度更新指示器（可用于滚动时的平滑过渡）
    public func updateIndicator(progress: CGFloat, fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0 && fromIndex < buttons.count,
              toIndex >= 0 && toIndex < buttons.count else { return }
        
        let fromButton = buttons[fromIndex]
        let toButton = buttons[toIndex]
        
        let fromCenterX = fromButton.center.x
        let toCenterX = toButton.center.x
        let currentCenterX = fromCenterX + (toCenterX - fromCenterX) * progress
        
        indicatorView.center.x = currentCenterX + stackView.frame.minX
    }
    
    // MARK: - Private Methods
    
    private func createButton(for item: TabItem, at index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(item.title, for: .normal)
        button.setTitleColor(config.normalColor, for: .normal)
        button.titleLabel?.font = config.normalFont
        button.tag = index
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectItem(at: index, animated: true)
        delegate?.tabBar(self, didSelectItemAt: index)
        onItemSelected?(index)
    }
}

