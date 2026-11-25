## laptus. ZERO
laptus. ZEROは、平塚中等教育学校の2026年度の文化祭のために科学部が制作した音ゲーである ***laptusꓸ*** のゲーム本体のデータを公開用にフリーの曲のみを残す形で要素を削減したバージョンです。
他の人の実装の参考になることや制作データの記録を目的として公開しています。

開発環境は[Godot](https://godotengine.org/)を使用して制作されています。

`content/`: アセット全般。Godotでリリースビルドを行う際は設定でこのフォルダをエクスポート対象に含める必要があります。

`work/`: アセットを自作する際の作業データ。`.svg`は[inkscape](http://inkscape.org/)の作業データで、`.ase`は[LibreSprite](https://libresprite.github.io)の作業データ

`ai_utils.gd`: vibe codingされている、人間が内容をちゃんとチェックしていない処理を隔離するために作ったファイル

## ライセンス
`content/fusion-pixel-font-10px-proportional-ttf-v2026.09.25`,
`content/fusion-pixel-font-12px-proportional-ttf-v2026.09.25`,
`content/songs`,`content/sounds`,`content/x8y12pxDenkiChip`
内のデータを**除く**全てのファイルは**CC BY-NC-SA 4.0**の元で公開されています。詳細は [LICENSE.txt](LICENSE.txt) ファイルを参照してください。

## 謝辞
本プロジェクトでは、以下のアセットを使用しています。利便性のため、全てのアセットは各ライセンスに基づきリポジトリ内に含まれています。

### 使用した曲
* [Dimrain47 - At the Speed of Light](https://www.newgrounds.com/audio/listen/467339) - `content/songs/467339-at-the-speed-of-light-fina_6H2rSnbg.mp3`に同梱
* [Creo - Dimension](https://www.newgrounds.com/audio/listen/709578) - `content/songs/Dimension.mp3`に同梱

### その他使った素材
* [魔王魂 サイバー33](https://maou.audio/bgm_cyber33/) - [独自ライセンス](https://maou.audio/rule/)(`content/maou_bgm_cyber33.mp3`に同梱)
* [でんきチップ](https://github.com/hicchicc/x8y12pxDenkiChip) - OFL License(`content/x8y12pxDenkiChip`に同梱)
* [Fusion Pixel Font](https://github.com/TakWolf/fusion-pixel-font) - OFL License(`content/fusion-pixel-font-10px-proportional-ttf-v2026.09.25`, `fusion-pixel-font-12px-proportional-ttf-v2026.09.25`に同梱)
* [【音ゲー効果音】ノートタップ音１](https://commons.nicovideo.jp/works/nc439923) - `content/sounds/ノートタップ音１.wav`に同梱
* [【音ゲー効果音】ノートタップ音２](https://commons.nicovideo.jp/works/nc439924) - `content/sounds/ノートタップ音２.wav`に同梱

でんきチップとFusion Pixel Fontは同梱フォルダ内にライセンスファイルが含まれています。ライセンス名が書かれていないものはリンク先を確認してください。

また、本プロジェクトの一部のコードは、AI（Gemini / ChatGPT等）による補助を受けて作成されました。
