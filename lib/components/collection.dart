import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import 'album.dart';
import 'emtpy.dart';

class CollectionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: Consumer<Collection>(
        builder: (context, collection, _) {
          if (collection.isUserEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: EmptyState(
                imagePath: 'assets/empty_nothing.png',
                headline: 'Anyone out there?',
                subhead: 'A Discogs account needs to be configured',
              ),
            );
          }
          if (collection.isEmpty && collection.isNotLoading) {
            return SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: collection.hasLoadingError
                  ? const EmptyState(
                      imagePath: 'assets/empty_error.png',
                      headline: 'Whoops!',
                      subhead:
                          'Could not connect to Discogs to get your collection. Please try again later.')
                  : const EmptyState(
                      imagePath: 'assets/empty_home.png',
                      headline: 'Nothing here',
                      subhead:
                          'It appears that the configured user collection is either empty, or not publically accessible.',
                    ),
            );
          }

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return AlbumButton(collection.albums[index]);
              },
              childCount: collection.albums.length,
            ),
          );
        },
      ),
    );
  }
}
