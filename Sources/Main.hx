// Auto-generated
package ;
class Main {
    public static inline var projectName = 'virtualwallproject';
    public static inline var projectVersion = '1.0';
    public static inline var projectPackage = 'arm';
    public static function main() {
        iron.object.BoneAnimation.skinMaxBones = 8;
        armory.system.Starter.numAssets = 17;
        armory.system.Starter.drawLoading = arm.LoadingScreen.render;
        armory.system.Starter.main(
            'Scene',
            1,
            true,
            true,
            false,
            1920,
            1080,
            1,
            true,
            armory.renderpath.RenderPathCreator.get
        );
    }
}
