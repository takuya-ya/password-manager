# パスワードマネージャー
パスワードを管理するパスワードマネージャーを作成しました。

## 前提条件
このパスワードマネージャーを使用するには、以下のソフトウェアが必要です：

### 共通要件
- **Bash** 3.2以降対応
- **GnuPG (GPG)** (暗号化ライブラリ)

### プラットフォーム別要件

#### macOS
- **Homebrew** (パッケージマネージャー)

#### Linux / WSL
- 標準的なLinuxディストリビューション（Ubuntu/Debian での動作確認済み）
- WSL (Windows Subsystem for Linux) での動作確認済み
- パッケージマネージャー (apt等)

## セットアップ手順

### macOS

#### 1. Homebrew のインストール
macOSのパッケージマネージャであるHomebrewをインストールします。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

インストール後、パスを設定します：
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### 2. GPG のインストール
```bash
brew install gnupg
```

### Linux / WSL

#### Ubuntu/Debian (動作確認済み)
```bash
# Linux (Ubuntu/Debian) または WSL (Ubuntu等) の場合
sudo apt update
sudo apt install gnupg
```

### インストールの確認 (全プラットフォーム共通)
GPGが正しくインストールされているか確認します。

```bash
gpg --version
```

バージョン情報が表示されれば、インストールは完了です。

## 使用方法

### スクリプトの実行

#### Unix系 (macOS, Linux, WSL)
```bash
./password_manager.sh
```

#### 実行権限の設定 (Unix系のみ)
```bash
chmod +x password_manager.sh
```

### 機能説明
1. メニューが表示されるので、希望のメニューを選択してください。
2. **Add Password**: サービス名、ユーザー名、パスワードを入力して下さい。
   入力内容を暗号化する為、パスフレーズの設定が求められます。尚、復帰処理が未実装の為、パスフレーズを紛失した場合、情報が取得できなくなります。パスフレーズの管理には十分にご注意ください。
3. **Get Password**: 情報を取得したいサービス名を入力して下さい。暗号化ファイル復号化の為、パスフレーズが求められます。
4. **Exit**: パスワードマネージャーを終了します。
5. 復号化の為に入力したパスフレーズは、一定時間キャッシュされる為、その間は入力がスキップされます。

## 技術仕様
- **暗号化方式**: GPG対称暗号化
- **対応シェル**: Bash 3.2以降
- **対応OS**:
  - macOS (動作確認済み)
  - Linux / WSL Ubuntu/Debian (動作確認済み)
- **データ形式**: コロン区切りテキスト
- **バリデーション**: 入力値検証とエラーハンドリング

## 注意事項
1. **シェル環境**: Bash 3.2以降での動作を確認済みです。Windows環境ではWSLでの動作を確認済みです。
2. **パスフレーズ管理**: パスフレーズを紛失した場合、保存した情報が取得できなくなります。パスフレーズの管理には十分にご注意ください。
3. **セキュリティ**: 暗号化ファイル（.gpg）とエラーログ（error.txt）が作業ディレクトリに作成されます。
4. **権限**: Unix系OSでは実行権限の設定が必要です：
   ```bash
   chmod +x password_manager.sh
   ```

## トラブルシューティング

### GPGコマンドが見つからない場合

#### macOS
```bash
# エラー例: gpg: command not found
# 解決策: GPGをインストール
brew install gnupg
```

#### Linux / WSL
```bash
# Linux (Ubuntu/Debian) または WSL (動作確認済み)
sudo apt install gnupg
```

### パスフレーズエラー
```bash
# GPGエージェントのリセット
gpgconf --kill gpg-agent
```

### 権限エラー

#### Unix系 (macOS, Linux, WSL)
```bash
# スクリプトに実行権限を付与
chmod +x password_manager.sh
```
