import UIKit

// MARK: - 用户信息模型
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
    
    // MARK: - UI Components
    private lazy var avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray4
        iv.layer.cornerRadius = 45
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
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
        stack.spacing = 30
        return stack
    }()
    
    private lazy var followButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("关注", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemPink
        btn.layer.cornerRadius = 22
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return btn
    }()
    
    private lazy var messageButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("私信", for: .normal)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .systemGray5
        btn.layer.cornerRadius = 22
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return btn
    }()
    
    /// 头像底部的 Y 坐标，用于判断 HeaderBar 何时显示标题
    var avatarBottomY: CGFloat {
        return avatarImageView.frame.maxY
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(userIdLabel)
        addSubview(bioLabel)
        addSubview(statsStackView)
        addSubview(followButton)
        addSubview(messageButton)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        userIdLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        followButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 90),
            avatarImageView.heightAnchor.constraint(equalToConstant: 90),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // User ID
            userIdLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            userIdLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // Bio
            bioLabel.topAnchor.constraint(equalTo: userIdLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            bioLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            // Stats
            statsStackView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 20),
            statsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // Buttons
            followButton.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 20),
            followButton.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -8),
            followButton.widthAnchor.constraint(equalToConstant: 120),
            followButton.heightAnchor.constraint(equalToConstant: 44),
            
            messageButton.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 20),
            messageButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 8),
            messageButton.widthAnchor.constraint(equalToConstant: 120),
            messageButton.heightAnchor.constraint(equalToConstant: 44),
            
            messageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with profile: UserProfile) {
        nameLabel.text = profile.name
        userIdLabel.text = "@\(profile.userId)"
        bioLabel.text = profile.bio
        
        // 清除旧的 stats
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的 stats
        let stats = [
            ("关注", profile.followingCount),
            ("粉丝", profile.followersCount),
            ("获赞", profile.likesCount)
        ]
        
        for (title, count) in stats {
            let statView = createStatView(count: count, title: title)
            statsStackView.addArrangedSubview(statView)
        }
    }
    
    private func createStatView(count: Int, title: String) -> UIView {
        let container = UIView()
        
        let countLabel = UILabel()
        countLabel.font = .systemFont(ofSize: 18, weight: .bold)
        countLabel.textColor = .label
        countLabel.text = formatNumber(count)
        countLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 13)
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
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1fw", Double(number) / 10000)
        }
        return "\(number)"
    }
}
