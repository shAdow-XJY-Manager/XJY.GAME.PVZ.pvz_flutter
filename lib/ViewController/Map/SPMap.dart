
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:shadow_pvz/Util/Asset/SPAsset.dart';
import 'package:shadow_pvz/Util/EventBus/SPEventBus.dart';
import 'package:shadow_pvz/Util/Log/SPLogger.dart';
import 'package:shadow_pvz/ViewController/Splash/SPMapSplash.dart';
import 'package:shadow_pvz/ViewModel/Map/import/SPMapViewModel.dart';

import '../../View/Map/import/SPMapView.dart';

class SPMap extends FlameGame with PanDetector, TapDetector {
  final SPVMMap _mapViewModel = SPVMMap();
  
  late final World _mapWorld;
  late final CameraComponent _cameraComponent;

  late final PositionComponent _mapComponent;
  List<Component> buildingList = [];
  static const zoom = 3.0;
  static const radius = 130.0;

  SPMap(bool isDebug) {
    debugMode = isDebug;
  }

  @override
  Future<void>? onLoad() async {
    // 背景图片
    add(SpriteComponent(
      sprite: await loadSprite(SPAssetImages.backgroundOfMap),
      size: size,
      position: size / 2,
      anchor: Anchor.center,
    ));

    // Create buildings from _mapViewModel
    for (final building in _mapViewModel.buildings) {
      buildingList.add(SPBuildingView(
        position: Vector2(building.positionX, building.positionY),
        onTap: _handleBuildingTap,
        type: building.type,
      ));
    }

    _mapWorld = World();
    await add(_mapWorld);

    // 创建地图组件
    _mapComponent = PositionComponent(
      size: Vector2(SPVMMap.mapWidth, SPVMMap.mapHeight),
      anchor: Anchor.center,
      children: buildingList,
    );


    _cameraComponent = CameraComponent(world: _mapWorld); // 然后将 _mapWorld 添加到 camera
    await add(_cameraComponent);

    // 设置相机边界
    _cameraComponent.setBounds(Rectangle.fromLTRB(
      -_mapComponent.size.x/4,
      -_mapComponent.size.y/4,
      _mapComponent.size.x/4,
      _mapComponent.size.y/4,
    ));

    add(SPMapSplash(startGame: () {
      _mapWorld.add(_mapComponent); // 先将 _mapComponent 添加到 _mapWorld
    })); // 将 SPMapSplash 添加到 _mapWorld
  }

  @override
  void onTapDown(TapDownInfo info) {
    SPLogger.d("SPMap onTapDown");
  }

  @override
  bool onPanUpdate(DragUpdateInfo info) {
    SPLogger.d("SPMap onPanUpdate ${-info.delta.global}");
    _cameraComponent.moveBy(-info.delta.global);
    return true;
  }

  // Callback function to handle building taps
  void _handleBuildingTap(SPVMBuildingType type) {
    eventBus.fire(SPMapEnterBuildingEvent(type));
  }
}