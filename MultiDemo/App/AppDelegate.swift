import UIKit

// MARK: - ================== App 入口 ==================

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// 保持 dataSource 强引用
    private var assetFlowDataSource: ProfileAssetFlowDataSource?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
/// 
/// 解耦设计：不再持有 NestedScrollManager
/// ProfileViewController 会在组装时自动绑定滚动回调
class ProfileAssetFlowDataSource: AssetFlowDataSource, AssetFlowDelegate {
    
    // MARK: - AssetFlowDataSource
    
    func assetFlowConfigs() -> [AssetFlowConfig] {
        return [
            // 出境模块 - 由开发者 A 开发
            AssetFlowConfig(title: "出境") {
                return AppearanceViewControllerRefactored()
            },
            
            // 创作模块 - 由开发者 B 开发
            AssetFlowConfig(title: "创作") {
                return CreationViewController()
            },
            
            // 互动模块 - 由开发者 C 开发
            AssetFlowConfig(title: "互动") {
                return InteractionViewController()
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
