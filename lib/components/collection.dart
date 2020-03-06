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

class CollectionLoadingStatus extends StatelessWidget {
  const CollectionLoadingStatus();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: Consumer2<Collection, LoadingStatus>(
        builder: (_, collection, status, __) {
          if (collection.isUserEmpty) {
            return const EmptyState(
              imagePath: 'assets/empty_nothing.png',
              headline: 'Anyone out there?',
              subhead: 'A Discogs account needs to be configured',
            );
          }

          if (collection.isEmpty && collection.isNotLoading) {
            return collection.hasLoadingError
                ? EmptyState(
                    imagePath: 'assets/empty_error.png',
                    headline: 'Whoops!',
                    subhead: collection.errorMessage ??
                        'Could not connect to Discogs to get your collection. Please try again later.')
                : const EmptyState(
                    imagePath: 'assets/empty_home.png',
                    headline: 'Nothing here',
                    subhead:
                        'It appears that the configured user collection is either empty, or not publically accessible.',
                  );
          }

          return Container(
            height: 80,
            child: status == LoadingStatus.loading
                ? Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  )
                : Container(),
          );
        },
      ),
    );
  }
}
