# slack to chatwork

slack botが画像をPOSTしてくるものをダウンロードして、chatworkにPOSTしなおします。

## Usage

```
$ COOKIEJAR=cookie.dat CW_ROOMID=YOUR_ROOM_ID CW_USERNAME=example@example.jp CW_PASSWORD=blahblahblah carton exec -- plackup
```

## License

MIT License

## Notes.

chatworkへのファイルアップロードの実装は、chatworkがファイルアップロードのAPIを公開していないため、現実のリクエストを元に実装しています。

そのため、この方法がいつ動かなくなるかわかりませんし、動かなくなった場合に、すぐに修正を行うかは無保証です。

