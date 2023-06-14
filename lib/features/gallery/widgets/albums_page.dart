import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../entities/asset_entity_plus.dart';
import '../controllers/album_controller.dart';
import '../controllers/albums_controller.dart';
import '../controllers/gallery_controller.dart';
import '../entities/album_entity.dart';
import 'albums_builder.dart';
import 'entity_thumbnail.dart';

const _imageSize = 48;

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({
    Key? key,
    required this.controller,
    required this.onAlbumChange,
    required this.albumsController,
  }) : super(key: key);

  final GalleryController controller;
  final ValueSetter<AlbumController> onAlbumChange;
  final AlbumsController albumsController;

  @override
  Widget build(BuildContext context) {
    return AlbumsBuilder(
      controller: controller,
      albumsController: albumsController,
      hidePermissionView: true,
      builder: (context, value) {
        if (value.albumControllers.isEmpty) {
          return Container(
            alignment: Alignment.center,
            color: Colors.black,
            child: const Text(
              'No albums',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        // Album list
        return ColoredBox(
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: value.albumControllers.length,
            itemBuilder: (context, index) {
              final album = value.albumControllers[index];
              return AlbumTile(
                controller: controller,
                albumController: album,
                onPressed: onAlbumChange,
              );
            },
          ),
        );
      },
    );
  }
}

class AlbumTile extends StatelessWidget {
  const AlbumTile({
    Key? key,
    required this.controller,
    required this.albumController,
    this.onPressed,
  }) : super(key: key);

  final GalleryController controller;
  final AlbumController albumController;
  final ValueChanged<AlbumController>? onPressed;

  AlbumEntity get album => albumController.value;

  Future<AssetEntity?> get firstAsset async {
    final assets = (await album.assetPathEntity?.getAssetListPaged(page: 0, size: 1)) ?? [];
    if (assets.isEmpty) return null;
    return assets.first;
  }

  @override
  Widget build(BuildContext context) {
    final isAll = album.assetPathEntity?.isAll ?? true;

    return GestureDetector(
      onTap: () => onPressed?.call(albumController),
      child: Container(
        padding: const EdgeInsets.only(left: 16, bottom: 20, right: 16),
        color: Colors.black,
        child: Row(
          children: [
            // Image
            Container(
              height: _imageSize.toDouble(),
              width: _imageSize.toDouble(),
              color: Colors.grey.shade800,
              child: FutureBuilder<AssetEntity?>(
                future: firstAsset,
                builder: (context, snapshot) {
                  final asset = snapshot.data;
                  if (snapshot.connectionState != ConnectionState.done || asset == null) {
                    return const SizedBox();
                  }
                  return ColoredBox(
                    color: Colors.grey.shade800,
                    child: AssetThumbnail(asset: asset.toPlus),
                  );
                },
              ),
            ),

            const SizedBox(width: 16),

            // Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album name
                  Text(
                    isAll ? 'All Photos' : album.assetPathEntity?.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Total photos
                  Text(
                    album.assetPathEntity?.assetCountAsync.toString() ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}