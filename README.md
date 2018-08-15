# LYPhotoBrowser

how to use

1. delegate: LYPhotoBrowserDelegate
  
2. photos,photo<br>
```NSMutableArray *photos = [NSMutableArray array];```<br>
```LYPhoto *photo;```<br>
photo<br>
```photo = [LYPhoto photoWithURL:[NSURL URLWithString:url]];```<br>
video<br>
```LYPhoto *photo = [LYPhoto photoWithURL:[NSURL URLWithString:url]];```<br>
            ```photo.videoURL = [NSURL URLWithString:url];```<br>
            caption<br>
            ```photo.caption = captions[i];```<br>
            ```[photos addObject:photo];```
3. ```LYPhotoBrowser *browser = [[LYPhotoBrowser alloc] initWithDelegate:self];```<br>
    ```[browser setCurrentPhotoIndex:1];```<br>
    ```[self presentViewController:browser animated:YES completion:nil];```
4. delegate
```
- (NSUInteger)numberOfPhotosInPhotoBrowser:(LYPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id<LYPhoto>)photoBrowser:(LYPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) return [_photos objectAtIndex:index];
    return nil;
}
