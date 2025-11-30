import UIKit

// MARK: - ================== 用户信息头部 ==================

// MARK: - 用户模型
struct UserProfile {
    let avatar: String
    let name: String
    let userId: String
    let bio: String
    let followingCount: Int
    let followersCount: Int
    let likesCount: Int
}

// MARK: - 用户信息头部视图
class ProfileHeaderView: UIView {
    
    /// 头像底部 Y 坐标（用于计算 HeaderBar 透明度）
    var avatarBottomY: CGFloat {
        return avatarView.frame.maxY
    }
    
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 40
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("编辑资料", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 16
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        addSubview(nameLabel)
        addSubview(userIdLabel)
        addSubview(bioLabel)
        addSubview(statsStackView)
        addSubview(editButton)
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        userIdLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 80),
            avatarView.heightAnchor.constraint(equalToConstant: 80),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            userIdLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            userIdLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            bioLabel.topAnchor.constraint(equalTo: userIdLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            bioLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            statsStackView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48),
            statsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48),
            
            editButton.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 16),
            editButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 120),
            editButton.heightAnchor.constraint(equalToConstant: 32),
            editButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with profile: UserProfile) {
        avatarLabel.text = String(profile.name.prefix(1))
        nameLabel.text = profile.name
        userIdLabel.text = "@\(profile.userId)"
        bioLabel.text = profile.bio
        
        // 清除旧的统计视图
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加统计项
        let stats = [
            ("关注", profile.followingCount),
            ("粉丝", profile.followersCount),
            ("获赞", profile.likesCount)
        ]
        
        for stat in stats {
            let view = createStatView(title: stat.0, count: stat.1)
            statsStackView.addArrangedSubview(view)
        }
    }
    
    private func createStatView(title: String, count: Int) -> UIView {
        let container = UIView()
        
        let countLabel = UILabel()
        countLabel.font = .systemFont(ofSize: 18, weight: .bold)
        countLabel.textColor = .label
        countLabel.text = formatCount(count)
        countLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title
        titleLabel.textAlignment = .center
        
        container.addSubview(countLabel)
        container.addSubview(titleLabel)
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: container.topAnchor),
            countLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        return container
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - ================== 顶部导航栏 ==================

class ProfileHeaderBar: UIView {
    
    /// 导航栏内容高度（不含安全区域）
    private let contentHeight: CGFloat = 44
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.alpha = 0
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.alpha = 0
        return label
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(backgroundView)
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(moreButton)
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 背景覆盖整个区域（包括状态栏）
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 按钮和标题在安全区域内，使用 safeAreaLayoutGuide
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: contentHeight),
            
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            moreButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 44),
            moreButton.heightAnchor.constraint(equalToConstant: contentHeight)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    func updateAppearance(progress: CGFloat) {
        backgroundView.alpha = progress
        titleLabel.alpha = progress
    }
}
