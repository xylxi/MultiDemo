import UIKit

// MARK: - ================== App 入口 ==================

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// 保持 dataSource 强引用
    private var assetFlowDataSource: ProfileAssetFlowDataSource?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // iOS 13+ 使用 SceneDelegate
        if #available(iOS 13.0, *) {
            // SceneDelegate 会处理 window 创建
        } else {
            // iOS 12 及以下使用传统方式
            window = UIWindow(frame: UIScreen.main.bounds)
            
            let profileVC = ProfileViewController()
            
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
            
            assetFlowDataSource = ProfileAssetFlowDataSource(scrollManager: profileVC.scrollManager)
            profileVC.assetFlowDataSource = assetFlowDataSource
            profileVC.assetFlowDelegate = assetFlowDataSource
            
            let nav = UINavigationController(rootViewController: profileVC)
            nav.setNavigationBarHidden(true, animated: false)
            
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    // MARK: - UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

// MARK: - ================== 资产流数据源实现示例 ==================

/// 资产流数据源
/// 外部通过实现此类来注入不同的资产流配置
class ProfileAssetFlowDataSource: AssetFlowDataSource, AssetFlowDelegate {
    
    private weak var scrollManager: NestedScrollManager?
    
    init(scrollManager: NestedScrollManager?) {
        self.scrollManager = scrollManager
    }
    
    // MARK: - AssetFlowDataSource
    
    func assetFlowConfigs() -> [AssetFlowConfig] {
        return [
            // 出境模块 - 由开发者 A 开发
            AssetFlowConfig(title: "出境") { [weak self] in
                let vc = AppearanceViewController()
                vc.setScrollManager(self?.scrollManager)
                return vc
            },
            
            // 创作模块 - 由开发者 B 开发
            AssetFlowConfig(title: "创作") { [weak self] in
                let vc = CreationViewController()
                vc.setScrollManager(self?.scrollManager)
                return vc
            }
            
            // 可以继续添加更多模块...
            // AssetFlowConfig(title: "收藏") { ... }
        ]
    }
    
    // MARK: - AssetFlowDelegate
    
    func assetFlowDidSwitchTo(index: Int, title: String) {
        print("[AssetFlowDelegate] 切换到: \(title) (index: \(index))")
    }
    
    func assetFlowDidLoadPage(at index: Int, page: AssetFlowPageProtocol) {
        print("[AssetFlowDelegate] 页面已加载: index=\(index)")
    }
}
