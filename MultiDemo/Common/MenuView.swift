import UIKit
import SnapKit

// MARK: - ================== 菜单组件（应用侧自定义） ==================

// MARK: - 菜单项模型
public struct MenuItem {
    public let title: String
    public var hasChildren: Bool
    
    public init(title: String, hasChildren: Bool = false) {
        self.title = title
        self.hasChildren = hasChildren
    }
}

// MARK: - 菜单代理
public protocol MenuViewDelegate: AnyObject {
    func menuView(_ menuView: MenuView, didSelectItemAt index: Int)
}

// MARK: - 菜单视图
public class MenuView: UIView {
    
    public weak var delegate: MenuViewDelegate?
    
    /// 菜单项选中回调（用于闭包方式）
    public var onItemSelected: ((Int) -> Void)?
    
    private var items: [MenuItem] = []
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .label
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    private var indicatorCenterXConstraint: Constraint?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(stackView)
        addSubview(indicatorView)
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-4)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(3)
            make.width.equalTo(24)
        }
    }
    
    public func configure(with items: [MenuItem]) {
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
    
    private func createButton(for item: MenuItem, at index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        var title = item.title
        if item.hasChildren {
            title += " ▾"
        }
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(.label, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.tag = index
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectItem(at: index, animated: true)
        delegate?.menuView(self, didSelectItemAt: index)
        onItemSelected?(index)
    }
    
    public func selectItem(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < buttons.count else { return }
        
        selectedIndex = index
        
        // 更新按钮状态
        buttons.enumerated().forEach { i, button in
            button.isSelected = (i == index)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: i == index ? .semibold : .medium)
        }
        
        // 更新指示器位置
        let selectedButton = buttons[index]
        
        indicatorView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(3)
            make.width.equalTo(24)
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
}
