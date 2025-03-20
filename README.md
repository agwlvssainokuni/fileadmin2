FileAdmin2 - ファイル管理
========================

# コマンドライン
```bash
fileadmin [options] 設定ファイル...
    --time TIME        基準日時指定 (省略時: システム日時)
    --[no-]validate    設定チェック (省略時: 設定チェックなし)
    --[no-]dry-run     ドライラン   (省略時: ドライランなし)
    --[no-]syslog      SYSLOG出力フラグ (省略時: SYSLOG出力する)
    --[no-]console     コンソール出力フラグ (省略時: コンソール出力しない)
```

# 設定ファイル
## 基本構成
```Ruby
FileAdmin.configure do
  # ここにファイル管理の設定を書く。
end
```

## 集約アーカイブ作成
複数のファイルを一つのZIPファイルにアーカイブする。
```Ruby
FileAdmin.configure do
  archive_many_to_one("{ログ出力時のラベル}") do |c|
    c.basedir = ""  # 処理の基点ディレクトリ。
    c.arcname = ""  # 作成するZIPアーカイブのファイル名。Time#strftime の %Y %m %d %H %M %S 指定可。
    c.owner = ""    # 作成するZIPアーカイブの所有者、グループと"{所有者}:{グループ}"の形式で指定。省略可。
    c.to_dir = ""   # ZIPアーカイブの作成先ディレクトリ。省略時は基点ディレクトリ。
    collect_by_generation do |t| end  # ZIPアーカイブに含めるファイルの収集条件。
    collect_by_threshold do |t| end   # ZIPアーカイブに含めるファイルの収集条件。
  end
end
```

## 単体アーカイブ作成
一ファイルあたり一つのZIPファイルにアーカイブする。
```Ruby
FileAdmin.configure do
  archive_one_to_one("{ログ出力時のラベル}") do |c|
    c.basedir = ""  # 処理の基点ディレクトリ。
    c.arcname = proc {|f| }   # 対象のファイル名から作成するZIPアーカイブファイル名を導出するブロック。
    c.owner = ""    # 作成するZIPアーカイブの所有者、グループと"{所有者}:{グループ}"の形式で指定。省略可。
    c.to_dir = ""   # ZIPアーカイブの作成先ディレクトリ。省略時は対象ファイルと同じディレクトリ。
    collect_by_generation do |t| end  # ZIPアーカイブにするファイルの収集条件。
    collect_by_threshold do |t| end   # ZIPアーカイブにするファイルの収集条件。
  end
end
```

## ファイル退避
ファイルを所定のディレクトリへ退避 (移動) する。
```Ruby
FileAdmin.configure do
  backup_file("{ログ出力時のラベル}") do |c|
    c.basedir = ""  # 処理の基点ディレクトリ。
    c.to_dir = ""   # ファイルの退避先ディレクトリ。
    collect_by_generation do |t| end  # 退避するファイルの収集条件。
    collect_by_threshold do |t| end   # 退避するファイルの収集条件。
  end
end
```

## ファイル削除
ファイルを削除する。
```Ruby
FileAdmin.configure do
  cleanup_file("{ログ出力時のラベル}") do |c|
    c.basedir = ""  # 処理の基点ディレクトリ。
    collect_by_generation do |t| end  # 削除するファイルの収集条件。
    collect_by_threshold do |t| end   # 削除するファイルの収集条件。
  end
end
```

## ファイルの収集条件
### 世代数条件
指定した並び順に並べ、所定の世代数分を末尾から除外したものを対象とする。(古いものを抽出)
```Ruby
    collect_by_generation do |t|
      t.pattern = [""]            # 収集対象のパスをワイルドカードで指定。複数可。
      t.extra_cond = proc {|f|}   # patternで抽出したファイルの追加抽出条件。省略可。
      t.comparator = proc {|a,b|} # 抽出したファイル名の並び順。patternを複数指定した場合は要素ごとに整列する。省略可。
      t.generation = 0            # comparator順に並べて末尾generation件を除いたものを対象とする (古いものを抽出)。
    end
```

### 閾値条件
実行日時から閾値文字列を生成。ファイル名の日時部分が閾値よりも小(<)のものを対象とする。(古いものを抽出)
```Ruby
    collect_by_threshold do |t|
      t.pattern = [""]            # 収集対象のパスをワイルドカードで指定。複数可。
      t.extra_cond = proc {|f|}   # patternで抽出したファイルの追加抽出条件。省略可。
      t.comparator = proc {|a,b|} # 抽出したファイル名の並び順。patternを複数指定した場合は要素ごとに整列する。省略可。
      t.slicer = proc {|f|}       # 抽出したファイル名から閾値と比較するための文字列を生成する。
      t.threshold = proc {|time|} # 実行日時から閾値文字列を生成する。この閾値文字列よりも小(<)のものを対象とする (古いものを抽出)。
    end
```
