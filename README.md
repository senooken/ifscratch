# ifscratch

## Local installation
Ken SENOO

stow を使ったローカルインストールスクリプトをまとめる。

このリポジトリのインストールスクリプトを使えば、どのUnix環境でもローカルでパッケージをインストールできることを目標とする。

install.body.sh の LOCAL 環境変数でインストール先を指定しておき、そこにインストールする。
LOCALには例えば以下のような値を想定する。

LOCAL=${HOME}/local


## Policy

* パッケージ名，バージョン番号，解凍コマンドやダウンロードURLなどをローカル変数に与えて，共通のインストール部のスクリプトを実行する。

このパッケージごとのインストール条件は，CSVファイルなどで管理したほうが扱いやすいのではないかな。

ifscratch.csvにインストールに必要な情報を全て記入しておいて，この情報を元にインストールする感じ。

まずは一番シンプルなzlibのインストールでの動作を確認する。

これがうまくいったら，configureのオプションが必要なケースとして，ncursesを試す。

その次に，追加コマンドの必要な例として，readlineを試す。

ファイルから情報を読み込む部分は一つの関数・コマンド (`parse_arg`) にして、将来のファイル形式変更に備える。

最低限必要な情報

- PKG: パッケージ名
- VER: バージョン番号
- TAG: タグ名
- URL: リポジトリーURL

parse_argで上記の情報を該当変数に格納すればいい？

グローバル変数にするか？あるいは$1-$4にするか？

ひとまず、グローバル変数で考える。

ファイルで最低限保存が必要なのは、URLくらいか。後は、最悪引数に渡してもいい。

### 最新バージョンの取得
以下のコマンドで、リモートからタグの情報を取得できる。

```
git ls-remote -t --sort=-version:refname
```

```
21767c654d31d2dccdde4330529775c6c5fd5389	refs/tags/v1.2.12^{}
7f5767285055ea07ffdaf90a64f877bc382f3cc3	refs/tags/v1.2.12
```

ここから抽出すればいい。

`sed 's@.*/@@; s@\^{}$@@'`

### 依存関係の自動処理

xcb-utilがxorg-macros (util-macros) を必要とするので、これでチェックするのがいいだろう。

ただし、util-macrosをリポジトリーからビルドする場合、autoreconf (autoconf)/aclocal (automake) が必要になる。

xcb-utilsのビルド時には、submoduleも必要になる。

xcb本体も必要になるのでやはりパス。

## TODO
- make check, make testの自動判定

## Dpendency

- gcc
- make
- git
- wget or curl -> どちらかが標準で入っている？
- tar -> tarかbsdtarが標準で入っている？またはcpio，bsdcpio，paxとかで代用がききそう？
- autoreconf
- stow (perl)
