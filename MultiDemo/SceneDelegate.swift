import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var dataSource: ProfileAssetFlowDataSource?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 创建 ProfileViewController
        let profileVC = ProfileViewController()
        // 通过 DataSource 注入资产流配置
        let dataSource = ProfileAssetFlowDataSource(scrollManager: profileVC.scrollManager)
        profileVC.assetFlowDataSource = dataSource
        // 可选：设置代理监听事件
        profileVC.assetFlowDelegate = dataSource
        self.dataSource = dataSource
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
