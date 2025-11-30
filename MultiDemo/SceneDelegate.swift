import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    /// 保持 dataSource 强引用，防止被释放
    private var assetFlowDataSource: ProfileAssetFlowDataSource?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 创建 ProfileViewController
        let profileVC = ProfileViewController()
        
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
        profileVC.configureProfile(profile)
        
        // 通过 DataSource 注入资产流配置（保持强引用）
        assetFlowDataSource = ProfileAssetFlowDataSource(scrollManager: profileVC.scrollManager)
        profileVC.assetFlowDataSource = assetFlowDataSource
        profileVC.assetFlowDelegate = assetFlowDataSource
        
        let nav = UINavigationController(rootViewController: profileVC)
        nav.setNavigationBarHidden(true, animated: false)
        
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
