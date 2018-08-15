# LYPhotoBrowser

how to use

1. delegate: LYPhotoBrowserDelegate
  
2. photos,photo<br>
```
NSMutableArray *photos = [NSMutableArray array];
LYPhoto *photo;
```
photo<br>
```
photo = [LYPhoto photoWithURL:[NSURL URLWithString:url]];
```

video<br>
```
LYPhoto *photo = [LYPhoto photoWithURL:[NSURL URLWithString:url]];
photo.videoURL = [NSURL URLWithString:url];
```
caption<br>
```
photo.caption = captions[i];
```

add<br>
```
[photos addObject:photo];
```

3. init
```
LYPhotoBrowser *browser = [[LYPhotoBrowser alloc] initWithDelegate:self];
[browser setCurrentPhotoIndex:1];
[self presentViewController:browser animated:YES completion:nil];
```

4. delegate
```
- (NSUInteger)numberOfPhotosInPhotoBrowser:(LYPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id<LYPhoto>)photoBrowser:(LYPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) return [_photos objectAtIndex:index];
    return nil;
}
```
