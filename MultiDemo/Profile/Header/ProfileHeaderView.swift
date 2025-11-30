import UIKit
import SnapKit

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
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        
        avatarLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        userIdLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        bioLabel.snp.makeConstraints { make in
            make.top.equalTo(userIdLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
        }
        
        statsStackView.snp.makeConstraints { make in
            make.top.equalTo(bioLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().offset(-48)
        }
        
        editButton.snp.makeConstraints { make in
            make.top.equalTo(statsStackView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().offset(-16)
        }
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
        
        countLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
        }
        
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
        
        // 背景覆盖整个区域（包括状态栏）
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 按钮和标题在安全区域内
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.size.equalTo(CGSize(width: 44, height: contentHeight))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
        
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(backButton)
            make.size.equalTo(CGSize(width: 44, height: contentHeight))
        }
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    func updateAppearance(progress: CGFloat) {
        backgroundView.alpha = progress
        titleLabel.alpha = progress
    }
}
