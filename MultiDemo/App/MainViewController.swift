import UIKit
import SnapKit

// MARK: - ================== 主视图控制器 ==================

/// 主视图控制器
/// 通过左滑手势拖出 ProfileViewController
class MainViewController: UIViewController {

    // MARK: - Properties

    /// 交互式转场控制器（用于手势驱动的转场）
    private var interactiveTransition: SlideInteractiveTransition?

    /// 当前正在 present 的 ProfileViewController（弱引用）
    private weak var presentedProfile: ProfileViewController?

    // MARK: - UI Components

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.text = "主页面\n\n向左滑动打开个人页面\n（或点击此处）"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleContentLabelTap)))
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(contentLabel)

        contentLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - ProfileViewController Factory

    private var dataSource: ProfileAssetFlowDataSource?
    
    private func createProfileViewController() -> ProfileViewController {
        let vc = ProfileViewController()

        // 配置用户信息
        let profile = UserProfile(
            avatar: "",
            name: "创作者小明",
            userId: "xiaoming_2024",
            bio: "热爱生活，热爱创作 ✨ 每天分享有趣的内容",
            followingCount: 256,
            followersCount: 12580,
            likesCount: 98700
        )
        vc.configureProfile(profile)

        // 通过 DataSource 注入资产流配置
        let dataSource = ProfileAssetFlowDataSource()
        vc.assetFlowDataSource = dataSource
        vc.assetFlowDelegate = dataSource

        // 设置自定义转场代理
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom
        self.dataSource = dataSource
        return vc
    }

    // MARK: - Actions

    @objc private func handleContentLabelTap() {
        let profileVC = createProfileViewController()
        // 使用系统默认 present，不设置自定义转场
        profileVC.transitioningDelegate = nil
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true)
    }

    // MARK: - Gesture Handling

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .began else { return }

        // 确保没有正在显示的 ProfileViewController
        guard presentedProfile == nil else { return }

        // 创建新的 ProfileViewController
        let profileVC = createProfileViewController()
        presentedProfile = profileVC

        // 创建交互式转场控制器
        interactiveTransition = SlideInteractiveTransition(
            gestureRecognizer: gesture,
            direction: .right,
            onComplete: { [weak self] in
                self?.interactiveTransition = nil
            }
        )

        // Present ProfileViewController
        present(profileVC, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGesture.velocity(in: view)

        // 检查是否是从右往左滑动（水平方向为主）
        return velocity.x < 0 && abs(velocity.x) > abs(velocity.y)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MainViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitionAnimator(direction: .right, isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitionAnimator(direction: .right, isPresenting: false)
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

// MARK: - ================== 滑动转场动画 ==================

enum SlideDirection {
    case left
    case right
}

/// 滑动转场动画器
class SlideTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: SlideDirection
    let isPresenting: Bool

    init(direction: SlideDirection, isPresenting: Bool) {
        self.direction = direction
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        let screenWidth = containerView.bounds.width

        if isPresenting {
            containerView.addSubview(toVC.view)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            toVC.view.frame.origin.x = screenWidth

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toVC.view.frame.origin.x = 0
            } completion: { _ in
                let completed = !transitionContext.transitionWasCancelled
                transitionContext.completeTransition(completed)
            }
        } else {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromVC.view.frame.origin.x = screenWidth
            } completion: { _ in
                let completed = !transitionContext.transitionWasCancelled
                transitionContext.completeTransition(completed)
            }
        }
    }
}

// MARK: - ================== 交互式转场控制器 ==================

/// 交互式滑动转场控制器
class SlideInteractiveTransition: UIPercentDrivenInteractiveTransition {
    private weak var gestureRecognizer: UIPanGestureRecognizer?
    private let direction: SlideDirection
    private var transitionContext: UIViewControllerContextTransitioning?
    private var onComplete: (() -> Void)?

    /// - Parameters:
    ///   - gestureRecognizer: 手势识别器
    ///   - direction: 滑动方向（.right 表示 present 从右滑入，.left 表示 dismiss 向右滑出）
    ///   - onComplete: 转场完成或取消后的回调
    init(gestureRecognizer: UIPanGestureRecognizer, direction: SlideDirection, onComplete: (() -> Void)? = nil) {
        self.gestureRecognizer = gestureRecognizer
        self.direction = direction
        self.onComplete = onComplete
        super.init()

        gestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
    }

    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        super.startInteractiveTransition(transitionContext)
    }

    @objc private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        guard let transitionContext = transitionContext else { return }

        let containerView = transitionContext.containerView
        let translation = gesture.translation(in: containerView)
        let velocity = gesture.velocity(in: containerView)
        let screenWidth = containerView.bounds.width

        // 计算进度
        // .right: present 从右滑入，用户向左滑，translation.x < 0
        // .left: dismiss 向右滑出，用户向右滑，translation.x > 0
        let progress: CGFloat
        if direction == .right {
            progress = min(1.0, max(0.0, -translation.x / screenWidth))
        } else {
            progress = min(1.0, max(0.0, translation.x / screenWidth))
        }

        switch gesture.state {
        case .changed:
            update(progress)

        case .ended, .cancelled:
            // 判断是否完成转场
            let shouldComplete: Bool
            if direction == .right {
                // present: 向左滑动完成
                shouldComplete = progress > 0.5 || velocity.x < -500
            } else {
                // dismiss: 向右滑动完成
                shouldComplete = progress > 0.5 || velocity.x > 500
            }

            if shouldComplete {
                finish()
            } else {
                cancel()
            }

            gestureRecognizer?.removeTarget(self, action: #selector(handleGesture(_:)))
            self.transitionContext = nil
            onComplete?()

        default:
            break
        }
    }
}
